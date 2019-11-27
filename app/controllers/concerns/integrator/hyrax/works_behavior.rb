# Reference
# https://github.com/samvera/hyrax/blob/master/app/controllers/concerns/hyrax/works_controller_behavior.rb
# https://github.com/samvera/hyrax/blob/master/app/controllers/hyrax/uploads_controller.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/factory/object_factory.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/files_parser.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/9643b649df513e404c96ba5b9285d83abc4b2c9a/lib/generators/leaf_addons/templates/lib/importer/factory/base_factory.rb
require 'securerandom'
require 'time'

module Integrator
  module Hyrax
    module WorksBehavior
      extend ActiveSupport::Concern

      def upload_files
        return if @files.blank?
        @file_ids = []
        @uploaded_files = {}
        @files.each do |file|
          u = ::Hyrax::UploadedFile.new
          @current_user = User.batch_user unless @current_user.present?
          u.user_id = @current_user.id unless @current_user.nil?
          u.file = ::CarrierWave::SanitizedFile.new(file)
          u.save
          chosen_file = @files_attributes.select{ |fa| File.basename(fa['filepath'][0]) == File.basename(file) }
          if chosen_file.any?
            chosen_file[0]['uploaded_file'] = u
            @uploaded_files[File.basename(file)] = chosen_file[0]
          else
            @file_ids << u.id
          end
        end
      end

      def add_work
        @object = find_work if @object.blank?
        if @object
          update_work
        else
          create_work
        end
        set_in_progress_status_and_push
      end

      def upload_files_with_attributes
        return if @uploaded_files.blank?
        @uploaded_files.each do |file_name, uploaded_file|
          create_file_set_with_attributes(uploaded_file)
        end
      end

      def find_work_by_query(work_id = params[:id])
        model = find_work_klass(work_id)
        return nil if model.blank?
        @work_klass = model.constantize
        @object = find_work(work_id)
      end

      def find_work(work_id = params[:id])
        # params[:id] = SecureRandom.uuid unless params[:id].present?
        return find_work_by_id(work_id) if work_id
      end

      def find_work_by_id(work_id = params[:id])
        @work_klass.find(work_id)
      rescue ActiveFedora::ActiveFedoraError
        nil
      end

      def update_work
        raise "Object doesn't exist" unless @object
        work_actor.update(environment(update_attributes))
      end

      def create_work
        attrs = create_attributes
        @object = @work_klass.new
        # Assign pid to object if it doesn't exist
        # Ensure pid becomes object ID (but don't try to save it, as pid isn't
        # a field in the Hyrax model)
        if attrs['id'].blank?
          uuid = SecureRandom.uuid
          pid = "uuid_#{uuid}"
        else
          pid = attrs['id']
          attrs.except!('id')
        end
        # Add record created date
        record_created_date = attrs['admin_information_attributes'].first.try(:[], 'record_created_date')
        unless record_created_date.present?
          attrs['admin_information_attributes'].first['record_created_date'] = DateTime.now().strftime("%Y-%m-%d")
        end
        @object.id = pid
        work_actor.create(environment(attrs))
      end

      private
        def create_attributes
          transform_attributes
        end

        def update_attributes
          transform_attributes.except(:id, 'id')
        end

        def set_work_klass
          # Transform name of model to match across name variations
          work_models = WillowSword.config.work_models
          if work_models.kind_of?(Array)
            work_models = work_models.map { |m| [m, m] }.to_h
          end
          work_models.transform_keys!{ |k| k.underscore.gsub('_', ' ').gsub('-', ' ').downcase }
          # Match with header first, then resource type and finally pick one from list
          hyrax_work_model = @headers.fetch(:hyrax_work_model, nil)
          if hyrax_work_model and work_models.include?(hyrax_work_model)
            # Read the class from the header
            @work_klass = work_models[hyrax_work_model].constantize
          elsif @resource_type and work_models.include?(@resource_type)
            # Set the class based on the resource type
            @work_klass = work_models[@resource_type].constantize
          else
            # TODO: Change this to 'Record' once that work type is created
            # https://trello.com/c/vl94Tpjj
            @work_klass = work_models['universal test object'].constantize
          end
        end

        # @param [Hash] attrs the attributes to put in the environment
        # @return [Hyrax::Actors::Environment]
        def environment(attrs)
          # Set Hyrax.config.batch_user_key
          @current_user = User.batch_user unless @current_user.present?
          ::Hyrax::Actors::Environment.new(@object, Ability.new(@current_user), attrs)
        end

        def work_actor
          ::Hyrax::CurationConcern.actor
        end

        # Override if we need to map the attributes from the parser in
        # a way that is compatible with how the factory needs them.
        def transform_attributes
          convert_contributor_affiliations
          # TODO: attributes are strings and not symbols
          @attributes['visibility'] = WillowSword.config.default_visibility if @attributes.fetch('visibility', nil).blank?
          if WillowSword.config.allow_only_permitted_attributes
           @attributes.slice(*permitted_attributes).merge(file_attributes)
          else
           @attributes.merge(file_attributes)
          end
          @attributes
        end

        def convert_contributor_affiliations
          # BizTalk can store alternative name forms for controlled affiliations values
          # Convert contributor affiliations to their canonical form
          return unless @attributes['contributors_attributes'].respond_to?(:each)
          affiliation_levels = [ :division, :department, :sub_department, :research_group, :sub_unit, :oxford_college]
          # set canonical names
          @attributes['contributors_attributes'].each do | contributor |
            affiliation_levels.each do | affiliation |
              next unless contributor[affiliation.to_s].present?
              if affiliation == :division
                canonical_name = DivisionsService.find_canonical_name(contributor[affiliation.to_s])
              else
                canonical_name = AltNamesService.find_canonical_name(contributor[affiliation.to_s], affiliation)
              end
              if defined?(canonical_name) and canonical_name.present?
                  contributor[affiliation.to_s] = canonical_name
              end
            end
            clean_duplicate_name_values contributor
          end
        end

        def clean_duplicate_name_values(contributor)
          # ensure that we unpick the values in ascending order
          affiliation_order = [:oxford_college, :sub_unit, :sub_department, :department, :division]
          affiliation_order.each do | key |
            # Skip there is no value at this level
            next unless contributor[key.to_s]
            level = AltNamesService.config[key]
            # Skip unless there is a parent
            next unless level[:parent]
            if contributor[key.to_s] == contributor[level[:parent].to_s]
              contributor[key.to_s] = ''
            end
          end
        end

        def file_attributes
          @file_ids.present? ? { uploaded_files: @file_ids } : {}
        end

        def permitted_attributes
          @work_klass.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end

        def find_work_klass(work_id)
          model = nil
          blacklight_config = Blacklight::Configuration.new
          search_builder = Blacklight::SearchBuilder.new([], blacklight_config)
          search_builder.merge(fl: 'id, has_model_ssim')
          search_builder.merge(fq: "{!raw f=id}#{work_id}")
          repository = Blacklight::Solr::Repository.new(blacklight_config)
          response = repository.search(search_builder.query)
          if response.dig('response', 'numFound') == 1
            model = response.dig('response', 'docs')[0]['has_model_ssim'][0]
          end
          model
        end

        def create_file_set_with_attributes(file_attributes)
          @file_set_klass = WillowSword.config.file_set_models.first.constantize
          file_set = @file_set_klass.create
          @current_user = User.batch_user unless @current_user.present?
          actor = file_set_actor.new(file_set, @current_user)
          actor.file_set.permissions_attributes = @object.permissions.map(&:to_hash)
          # Add file
          if file_attributes.fetch('uploaded_file', nil)
            actor.create_content(file_attributes['uploaded_file'])
          end
          title = Array(file_attributes.dig('mapped_metadata', 'file_name'))
          unless title.any?
            filepath = Array(file_attributes.fetch('filepath', nil))
            title = Array(File.basename(filepath[0])) if filepath.any?
          end
          actor.file_set.title = title
          # update_metadata
          unless file_attributes['mapped_metadata'].blank?
            chosen_attributes = file_set_attributes(file_attributes['mapped_metadata'])
            actor.file_set.update(chosen_attributes)
            actor.file_set.save!
          end
          actor.attach_to_work(@object) if @object
        end

        def file_set_attributes(attributes)
          if WillowSword.config.allow_only_permitted_attributes
            attributes.slice(*permitted_file_attributes).except(:id, 'id')
          else
            attributes.except(:id, 'id')
          end
        end

        def file_set_actor
          ::Hyrax::Actors::FileSetActor
        end

        def permitted_file_attributes
          @file_set_klass.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end

        def set_in_progress_status_and_push
          # If a deposit is in progress, or has been completed, set the relevant
          # in progress and requires review flags and push to review if required
          # Add in-progress header
          return if @headers[:in_progress].blank?
          status = @headers[:in_progress]
          if status.downcase == 'true'
            @object.admin_information.first['deposit_in_progress'] = true
            @object.save
          elsif status.downcase == 'false'
            @object.admin_information.first['deposit_in_progress'] = false
            @object.admin_information.first['record_requires_review'] = true
            @object.save
            push_work_to_review
          end
        end

        def push_work_to_review
          # Push a work to the review server for further processing
          user_email = WillowSword.config.default_user_email
          user = User.find_by(email: user_email)
          work = ActiveFedora::Base.find(@object.id)

          current_workflow_state = work.sipity_entity.workflow_state_name
          if current_workflow_state == 'draft'
            workflow_action_form = ::Hyrax::Forms::WorkflowActionForm.new(
                current_ability: user.ability,
                work: work,
                attributes: {name: 'submit'}
            )
            push = workflow_action_form.save
          else
            push = ::Hyrax::Workflow::TransferToReview.call(
                target: work, comment: nil, user: user)
          end

          if defined?(push) and push.present?
            Rails.logger.info "#{@object.id} sent to review"
            return true
          else
            Rails.logger.error "Could not send #{@object.id} to Review"
          end
        end
    end
  end
end

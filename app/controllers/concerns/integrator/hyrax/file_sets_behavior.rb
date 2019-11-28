module Integrator
  module Hyrax
    module FileSetsBehavior
      extend ActiveSupport::Concern

      def find_file_set
        return find_file_set_by_id if params[:id]
      end

      def create_file_set
        @file_set = @file_set_klass.create
        @current_user = User.batch_user unless @current_user.present?
        @actor = file_set_actor.new(@file_set, @current_user)
        @actor.file_set.permissions_attributes = @object.permissions.map(&:to_hash)
        # Add file
        unless @files.blank?
          chosen_file = @files.first
          f = upload_file(chosen_file)
          @actor.create_content(f)
          @actor.file_set.title = [File.basename(chosen_file)]
        end
        # update_metadata
        @actor.file_set.update(create_file_set_attributes) unless @attributes.blank?
        @actor.file_set.save!
        @actor.attach_to_work(@object) if @object
        set_in_progress_status_for_parent_work_and_push
      end

      def update_file_set
        raise "File set doesn't exist" unless @file_set
        @current_user = User.batch_user unless @current_user.present?
        @actor = file_set_actor.new(@file_set, @current_user)
        @actor.file_set.permissions_attributes = @object.permissions.map(&:to_hash)
        # update file
        unless @files.blank?
          chosen_file = @files.first
          f = upload_file(chosen_file)
          @actor.update_content(f)
          @actor.file_set.title = [File.basename(chosen_file)]
        end
        # update_metadata
        @actor.file_set.update(update_file_set_attributes) unless @attributes.blank?
        @actor.file_set.save!
        set_in_progress_status_for_parent_work_and_push
      end

      private

        def set_in_progress_status_for_parent_work_and_push
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
            Rails.logger.info "#{work.id} sent to review"
            return true
          else
            Rails.logger.error "Could not send #{@object.id} to Review"
          end
        end

        def find_file_set_by_id
          @file_set_klass.find(params[:id]) if @file_set_klass.exists?(params[:id])
        rescue ActiveFedora::ActiveFedoraError
          nil
        end

        def create_file_set_attributes
          transform_file_set_attributes.except(:id, 'id')
        end

        def update_file_set_attributes
          transform_file_set_attributes.except(:id, 'id')
        end

        def set_file_set_klass
          @file_set_klass = WillowSword.config.file_set_models.first.constantize
        end

        def transform_file_set_attributes
          if WillowSword.config.allow_only_permitted_attributes
            @attributes.slice(*permitted_file_set_attributes)
          end
          # Code needs to be here in order to fire on create OR update
          if WillowSword.config.check_back_by_default
            unless @attributes['file_embargo_release_method']
              @attributes['file_embargo_release_method'] = 'Check back'
            end
          end
          if WillowSword.config.default_embargo_end_date
            unless @attributes['file_embargo_end_date']
              @attributes['file_embargo_end_date'] = WillowSword.config.default_embargo_end_date
              @attributes['file_embargo_comment'] = @attributes['file_embargo_comment'].to_s + 'Automatically set by Sword2'
            end
          end

          # Auto-set file versions as well as RIOXX version.
          # TODO: refactor Hyrax code so that rioxx_version and file_version are used properly
          if @attributes['file_rioxx_file_version'].present?
            unless @attributes['file_version'].present?
              @attributes['file_version'] = map_rioxx_file_versions(@attributes['file_rioxx_file_version']) || ''
            end
          end

          # Set last updated value (format from Hyrax::Workflow::SetSubmittedAttributes date format)
          @attributes['last_updated'] = [DateTime.now.strftime("%Y-%m-%dT%H:%M:%SZ")]
          @attributes
        end

        def map_rioxx_file_versions(rioxx_version)
          rioxx_expansions = {
              'AO' => "Author's original",
              'SMUR' => "Submitted manuscript under review",
              'AM' => "Accepted manuscript",
              'P' => "Proof",
              'VOR' => "Version of record",
              'EVOR' => "Enhanced version of record",
              'CVOR' => "Corrected version of record",
              'NA' => "Not applicable (or unknown)"
          }
          rioxx_expansions[rioxx_version]
        end

        def permitted_file_set_attributes
          @file_set_klass.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end

        def file_set_actor
          ::Hyrax::Actors::FileSetActor
        end

        def upload_file(file)
          u = ::Hyrax::UploadedFile.new
          @current_user = User.batch_user unless @current_user.present?
          u.user_id = @current_user.id unless @current_user.nil?
          u.file = ::CarrierWave::SanitizedFile.new(file)
          u.save
          u
        end
    end
  end
end

# Reference
# https://github.com/samvera/hyrax/blob/master/app/controllers/concerns/hyrax/works_controller_behavior.rb
# https://github.com/samvera/hyrax/blob/master/app/controllers/hyrax/uploads_controller.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/factory/object_factory.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/files_parser.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/9643b649df513e404c96ba5b9285d83abc4b2c9a/lib/generators/leaf_addons/templates/lib/importer/factory/base_factory.rb

module Integrator
  module Hyrax
    module WorksBehavior
      extend ActiveSupport::Concern

      def upload_files
        # puts 'In upload_files'
        @file_ids = []
        @files.each do |file|
          u = ::Hyrax::UploadedFile.new
          u.user_id = User.find_by_user_key(User.batch_user_key).id unless User.find_by_user_key(User.batch_user_key).nil?
          u.file = ::CarrierWave::SanitizedFile.new(file)
          u.save
          @file_ids << u.id
        end
        # puts "Files uploaded: #{@file_ids}"
      end

      def add_work
        # puts 'In add_work'
        @object = find_work
        if @object
          update_work
        else
          create_work
        end
      end

      def find_work
        # puts 'In find_work'
        # params[:id] = SecureRandom.uuid unless params[:id].present?
        return find_work_by_id if params[:id]
      end

      def find_work_by_id
        # puts 'In find_work_by_id'
        work_klass.find(params[:id]) if work_klass.exists?(params[:id])
      end

      def update_work
        # puts 'In update_work'
        raise "Object doesn't exist" unless @object
        work_actor.update(environment(update_attributes))
      end

      def create_work
        puts 'In create_work'
        attrs = create_attributes
        @object = work_klass.new
        work_actor.create(environment(attrs))
        puts headers
        puts '-'*50
        puts @work_klass
      end

      def create_attributes
        # puts 'In create_attributes'
        transform_attributes
      end

      def update_attributes
        # puts 'In update_attributes'
        transform_attributes.except(:id)
      end

      private
        def set_work_klass
          if headers[:hyrax_work_model] && WillowSword.config.work_models.include?(headers[:hyrax_work_model])
            @work_klass = headers[:hyrax_work_model].constantize
          else
            @work_klass = WillowSword.config.work_models.first.constantize
          end
        end

        # @param [Hash] attrs the attributes to put in the environment
        # @return [Hyrax::Actors::Environment]
        def environment(attrs)
          # Set Hyrax.config.batch_user_key
          ::Hyrax::Actors::Environment.new(@object, Ability.new(User.batch_user), attrs)
        end

        def work_actor
          ::Hyrax::CurationConcern.actor
        end

        # Override if we need to map the attributes from the parser in
        # a way that is compatible with how the factory needs them.
        def transform_attributes
          # attributes.slice(*permitted_attributes).merge(file_attributes)
          attributes.merge(file_attributes)
        end

        def file_attributes
          @file_ids.present? ? { uploaded_files: @file_ids } : {}
        end

        def permitted_attributes
          work_klass.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end
    end
  end
end

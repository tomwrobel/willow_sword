# Reference
# https://github.com/samvera/hyrax/blob/master/app/controllers/concerns/hyrax/works_controller_behavior.rb
# https://github.com/samvera/hyrax/blob/master/app/controllers/hyrax/uploads_controller.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/factory/object_factory.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/master/lib/generators/leaf_addons/templates/lib/importer/files_parser.rb
# https://github.com/leaf-research-technologies/leaf_addons/blob/9643b649df513e404c96ba5b9285d83abc4b2c9a/lib/generators/leaf_addons/templates/lib/importer/factory/base_factory.rb

module WillowSword
  module Hyrax
    module WorksBehavior
      extend ActiveSupport::Concern

      def upload_files
        @file_ids = []
        @files.each do |file|
          u = Hyrax::UploadedFile.new
          u.user_id = User.find_by_user_key(User.batch_user_key).id unless User.find_by_user_key(User.batch_user_key).nil?
          u.file = CarrierWave::SanitizedFile.new(file)
          u.save
          @file_ids << u.id
        end
      end

      def add_work
        @object = find
        if @object
          update_work
        else
          create_work
        end
      end

      def find
        return find_by_id if attributes[:id]
        raise "Missing identifier: Unable to search for existing object without the ID"
      end

      def find_by_id
        klass.find(attributes[:id]) if klass.exists?(attributes[:id])
      end

      def update_work
        raise "Object doesn't exist" unless @object
        # run_callbacks(:save) do
        work_actor.update(environment(update_attributes))
        # end
        # log_updated(object)
      end

      def create_work
        attrs = create_attributes
        @object = klass.new
        work_actor.create(environment(attrs))
      end

      def create_attributes
        transform_attributes
      end

      def update_attributes
        transform_attributes.except(:id)
      end

      private
        # @param [Hash] attrs the attributes to put in the environment
        # @return [Hyrax::Actors::Environment]
        def environment(attrs)
          # Set Hyrax.config.batch_user_key
          Hyrax::Actors::Environment.new(@object, Ability.new(User.batch_user), attrs)
        end

        def work_actor
          Hyrax::CurationConcern.actor
        end

        # Override if we need to map the attributes from the parser in
        # a way that is compatible with how the factory needs them.
        def transform_attributes
          attributes.slice(*permitted_attributes).merge(file_attributes)
          # StringLiteralProcessor.process(attributes.slice(*permitted_attributes))
          #                      .merge(file_attributes)
        end

        def file_attributes
          @file_ids.present? ? { uploaded_files: @file_ids } : {}
        end

        # def file_attributes
        #   hash = {}
        #   hash[:remote_files] = attributes[:remote_files] if attributes[:remote_files].present?
        #   hash[:uploaded_files] = attributes[:uploaded_files] if attributes[:uploaded_files].present?
        #   hash
        # end

        def permitted_attributes
          klass.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end
    end
  end
end

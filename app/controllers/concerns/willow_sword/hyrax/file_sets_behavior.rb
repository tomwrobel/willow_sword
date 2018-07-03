module WillowSword
  module Hyrax
    module FileSetsBehavior
      extend ActiveSupport::Concern

      def find_file_set
        puts 'In find_file_set'
        return find_file_set_by_id if params[:id]
      end

      def find_file_set_by_id
        puts 'In find_file_set_by_id'
        FileSet.find(params[:id]) if FileSet.exists?(params[:id])
      end

      def update_file_set
        puts 'In update_file_set'
        raise "File set doesn't exist" unless @file_set
        @file_set.update!(file_set_update_attributes)
      end

      def file_set_update_attributes
        puts 'In file_set_update_attributes'
        transform_file_set_attributes.except(:id)
      end

      private
        def transform_file_set_attributes
          attributes.slice(*file_set_permitted_attributes)
        end

        def file_set_permitted_attributes
          FileSet.properties.keys.map(&:to_sym) + [:id, :edit_users, :edit_groups, :read_groups, :visibility]
        end
    end
  end
end

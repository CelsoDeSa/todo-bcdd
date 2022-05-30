# frozen_string_literal: true

module Todos
  class Item::CompleteController < BaseController
    def update
      scope = ::Todo::Item::Scope.new(owner_id: current_user.id, id: params[:id])

      ::Todo::Item::Complete
        .call(scope:)
        .on_success { redirect_after_updating }
        .on_failure(:todo_not_found) { handle_todo_not_found }
        .on_unknown { raise NotImplementedError }
    end

    private

      def redirect_after_updating
        redirect_to(todos_completed_path, notice: 'The to-do has become completed.')
      end

      def handle_todo_not_found
        redirect_back_or_to(todos_uncompleted_path, notice: 'To-do not found or unavailable.')
      end
  end
end

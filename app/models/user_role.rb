class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :form, optional: true

  validates :role, presence: true

  module Role
    FormManager = "form_manager"
    SubmissionViewer = "submission_viewer"
    ResponseViewer = "response_viewer"
  end

  ROLES = [
    UserRole::Role::FormManager,
    UserRole::Role::SubmissionViewer,
    UserRole::Role::ResponseViewer
  ]

  def valid_role?
    ROLES.include?(self.role)
  end
end

# frozen_string_literal: true

module User
  class Authentication::Process < ::Micro::Case
    attribute :email, default: ->(value) { ::User::Email.new(value) }
    attribute :password, default: ->(value) { ::User::Password.new(value) }

    def call!
      user = Record.find_by(email: email.value)

      return Failure(:user_not_found) unless user

      return Failure(:invalid_password) unless ::User::Password.match?(user.encrypted_password, password)

      Success :user_found, result: {user:}
    end
  end
end

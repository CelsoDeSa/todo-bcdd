# frozen_string_literal: true

::Rails.application.config.app_middleware.use ::Warden::Manager do |config|
  config.scope_defaults(
    :user,
    store: true,
    action: :unauthenticated_web,
    strategies: [:password]
  )

  config.scope_defaults(
    :api_v1,
    store: false,
    action: :unauthenticated_api,
    strategies: [:api_token]
  )

  config.failure_app = ->(env) do
    case env.dig('warden.options', :action)
    when :unauthenticated_web
      env['todo_bcdd'] = {unauthenticated: 'You need to sign in or sign up before continuing.'}

      ::Users::SessionsController.action(:new).call(env)
    when :unauthenticated_api
      [401, {'Content-Type' => 'application/json'}, ['{}']]
    else
      raise NotImplementedError
    end
  end
end

::Warden::Strategies.add(:password) do
  def valid?
    email_and_password = scoped_params.slice('email', 'password')

    ::User::Authentication::ValidateEmailAndPassword.call(email_and_password).success?
  end

  def authenticate!
    email_and_password = scoped_params.slice('email', 'password')

    ::User::Authentication::Process.call(email_and_password) do |on|
      on.failure { fail!('Incorrect email or password.') }
      on.success { |result| success!(result[:user]) }
    end
  end

  private

    def scoped_params
      @scoped_params ||= params.fetch('user', {})
    end
end

::Warden::Manager.serialize_into_session(:user, &:id)

::Warden::Manager.serialize_from_session(:user) do |id|
  ::User::Authentication::GetById.call(id:) do |on|
    on.failure { raise NotImplementedError }
    on.success { |result| result[:user] }
  end
end

::Warden::Strategies.add(:api_token) do
  def valid?
    access_token.present?
  end

  def authenticate!
    user = ::User.find_by(api_token: access_token)

    return success!(user) if user

    fail!('Invalid access_token')
  end

  private

    def access_token
      @access_token ||= request.get_header('HTTP_X_ACCESS_TOKEN')
    end
end

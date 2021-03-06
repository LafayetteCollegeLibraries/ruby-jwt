# frozen_string_literal: true
require 'jwt/error'

module JWT
  # JWT verify methods
  class Verify
    class << self
      %w(verify_aud verify_expiration verify_iat verify_iss verify_jti verify_not_before verify_sub).each do |method_name|
        define_method method_name do |payload, options|
          new(payload, options).send(method_name)
        end
      end
    end

    def initialize(payload, options)
      @payload = payload
      @options = options
    end

    def verify_aud
      return unless (options_aud = extract_option(:aud))
      raise(JWT::InvalidAudError, "Invalid audience. Expected #{options_aud}, received #{@payload['aud'] || '<none>'}") if ([*@payload['aud']] & [*options_aud]).empty?
    end

    def verify_expiration
      return unless @payload.include?('exp')
      raise(JWT::ExpiredSignature, 'Signature has expired') if @payload['exp'].to_i <= (Time.now.to_i - exp_leeway)
    end

    def verify_iat
      return unless @payload.include?('iat')
      raise(JWT::InvalidIatError, 'Invalid iat') if !@payload['iat'].is_a?(Numeric) || @payload['iat'].to_f > (Time.now.to_f + iat_leeway)
    end

    def verify_iss
      return unless (options_iss = extract_option(:iss))
      raise(JWT::InvalidIssuerError, "Invalid issuer. Expected #{options_iss}, received #{@payload['iss'] || '<none>'}") if @payload['iss'].to_s != options_iss.to_s
    end

    def verify_jti
      options_verify_jti = extract_option(:verify_jti)
      if options_verify_jti.respond_to?(:call)
        raise(JWT::InvalidJtiError, 'Invalid jti') unless options_verify_jti.call(@payload['jti'])
      elsif @payload['jti'].to_s.strip.empty?
        raise(JWT::InvalidJtiError, 'Missing jti')
      end
    end

    def verify_not_before
      return unless @payload.include?('nbf')
      raise(JWT::ImmatureSignature, 'Signature nbf has not been reached') if @payload['nbf'].to_i > (Time.now.to_i + nbf_leeway)
    end

    def verify_sub
      return unless (options_sub = extract_option(:sub))
      raise(JWT::InvalidSubError, "Invalid subject. Expected #{options_sub}, received #{@payload['sub'] || '<none>'}") unless @payload['sub'].to_s == options_sub.to_s
    end

    private

    def extract_option(key)
      @options.values_at(key.to_sym, key.to_s).compact.first
    end

    def global_leeway
      extract_option :leeway
    end

    def exp_leeway
      extract_option(:exp_leeway) || global_leeway
    end

    def iat_leeway
      extract_option(:iat_leeway) || global_leeway
    end

    def nbf_leeway
      extract_option(:nbf_leeway) || global_leeway
    end
  end
end

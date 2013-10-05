class ApplicationController < ActionController::Base

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end
  
    protect_from_forgery

      def after_sign_out_path_for(resource_or_scope)
        root_path
      end
      def after_sign_in_path_for(resource)
        root_path
      end
      def after_sign_up_path_for(resource)
        root_path
      end
      end

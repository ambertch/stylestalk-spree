# ++
# Copyright (c) 2007-2012, Spree Commerce, Inc. and other contributors
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the Spree Commerce, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived from this
#       software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# --

# ++
# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# --

# Modified version of the ssl_requirement plugin by DHH
module SslRequirement
  extend ActiveSupport::Concern

  included do
    before_filter(:ensure_proper_protocol)
  end

  module ClassMethods
    # Specifies that the named actions requires an SSL connection to be performed (which is enforced by ensure_proper_protocol).
    def ssl_required(*actions)
      class_attribute(:ssl_required_actions)
      self.ssl_required_actions = actions
    end

    def ssl_allowed(*actions)
      class_attribute(:ssl_allowed_actions)
      self.ssl_allowed_actions = actions
    end
  end

  protected
    # Returns true if the current action is supposed to run as SSL
    def ssl_required?
      if self.class.respond_to?(:ssl_required_actions)
        actions = self.class.ssl_required_actions
        actions.empty? || actions.include?(action_name.to_sym)
      else
        return false
      end
    end

    def ssl_allowed?
      if self.class.respond_to?(:ssl_allowed_actions)
        actions = self.class.ssl_allowed_actions
        actions.empty? || actions.include?(action_name.to_sym)
      else
        return false
      end
    end

  private

    def ssl_supported?
      return Spree::Config[:allow_ssl_in_production] if Rails.env.production?
      return Spree::Config[:allow_ssl_in_staging] if Rails.env.staging?
      return Spree::Config[:allow_ssl_in_development_and_test] if (Rails.env.development? or Rails.env.test?)
    end

    def ensure_proper_protocol
      return true if ssl_allowed?
      if ssl_required? && !request.ssl? && ssl_supported?
        redirect_to "https://" + request.host + request.fullpath
        flash.keep
      # AH
      # elsif request.ssl? && !ssl_required?
      #   redirect_to "http://" + request.host + request.fullpath
      #   flash.keep
      end

    end
end

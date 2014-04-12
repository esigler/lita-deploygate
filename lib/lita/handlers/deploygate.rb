module Lita
  module Handlers
    class Deploygate < Handler
      route(
        /^(deploygate|dg)\sadd\s(\S+)\s(\S+)$/,
        :add,
        command: true,
        help: {
          t('help.add_key') => t('help.add_value')
        }
      )

      route(
        /^(deploygate|dg)\sremove\s(\S+)\s(\S+)$/,
        :remove,
        command: true,
        help: {
          t('help.remove_key') => t('help.remove_value')
        }
      )

      route(
        /^(deploygate|dg)\slist\s(\S+)$/,
        :list,
        command: true,
        help: {
          t('help.list_key') => t('help.list_value')
        }
      )

      def self.default_config(config)
        config.user_name      = nil
        config.api_key        = nil
        config.default_app_id = nil
      end

      def add(response)
        app = response.matches[0][2]
        user = response.matches[0][1]
        response.reply(change(app, 'post', 'add.success', user))
      end

      def remove(response)
        app = response.matches[0][2]
        user = response.matches[0][1]
        response.reply(change(app, 'delete', 'remove.success', user))
      end

      def list(response)
        app = response.matches[0][1]
        users = members(app)
        if users.is_a? Array
          response.reply(t('list.none', app: app)) unless users.count > 0
          users.each do |user|
            response.reply(t('list.user', app: app, user: user['name'],
                                          role: user['role']))
          end
        else
          response.reply(users)
        end
      end

      private

      def change(app, method, success_key, user)
        if valid_app_name?(app)
          if api_request(method, "/#{app_path(app)}/members",
                         'users' => "[#{user}]")
            t(success_key, app: app, user: user)
          else
            t('error.request')
          end
        else
          t('error.unknown_app', app: app)
        end
      end

      def members(app)
        if valid_app_name?(app)
          result = api_request('get', "/#{app_path(app)}/members")
          if result
            result['results']['users']
          else
            t('error.request')
          end
        else
          t('error.unknown_app', app: app)
        end
      end

      def valid_app_name?(name)
        Lita.config.handlers.deploygate.app_names.key?(name)
      end

      def app_path(name)
        Lita.config.handlers.deploygate.app_names[name]
      end

      def api_request(method, component, args = {})
        if Lita.config.handlers.deploygate.user_name.nil? ||
           Lita.config.handlers.deploygate.api_key.nil?
          Lita.logger.error('Missing API key or Page ID for Deploygate')
          fail 'Missing config'
        end

        url = "https://deploygate.com/api/users/" \
              "#{Lita.config.handlers.deploygate.user_name}" \
              "#{component}"

        args['token'] = Lita.config.handlers.deploygate.api_key

        http_response = http.send(method) do |req|
          req.url url, args
        end

        if http_response.status == 200 || http_response.status == 201
          MultiJson.load(http_response.body)
        else
          Lita.logger.error("HTTP #{method} for #{url} with #{args} " \
                            "returned #{http_response.status}")
          Lita.logger.error(http_response.body)
          nil
        end
      end
    end

    Lita.register_handler(Deploygate)
  end
end

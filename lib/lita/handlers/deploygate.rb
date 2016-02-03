module Lita
  module Handlers
    class Deploygate < Handler
      config :user_name, required: true
      config :api_key, required: true
      config :app_names

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

      # rubocop:disable Metrics/AbcSize
      def list(response)
        app = response.matches[0][1]
        users = members(app)
        return response.reply(users) unless users.is_a? Array
        return response.reply(t('list.none', app: app)) unless users.count > 0
        users.each do |user|
          response.reply(t('list.user', app: app, user: user['name'],
                                        role: user['role']))
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def change(app, method, success_key, user)
        return t('error.unknown_app', app: app) unless valid_app_name?(app)
        result = api_request(method,
                             "/#{app_path(app)}/members",
                             'users' => "[#{user}]")
        return t('error.request') unless result
        t(success_key, app: app, user: user)
      end

      def members(app)
        return t('error.unknown_app', app: app) unless valid_app_name?(app)
        result = api_request('get', "/#{app_path(app)}/members")
        return t('error.request') unless result
        result['results']['users']
      end

      def valid_app_name?(name)
        Lita.config.handlers.deploygate.app_names.key?(name)
      end

      def app_path(name)
        Lita.config.handlers.deploygate.app_names[name]
      end

      # rubocop:disable Metrics/AbcSize
      def api_request(method, component, args = {})
        url = "https://deploygate.com/api/users/#{config.user_name}#{component}"
        args['token'] = config.api_key

        http_response = http.send(method) do |req|
          req.url url, args
        end

        unless http_response.status == 200 || http_response.status == 201
          log.error("#{method}:#{component}:#{args}:#{http_response.status}")
          return nil
        end

        MultiJson.load(http_response.body)
      end
      # rubocop:enable Metrics/AbcSize
    end

    Lita.register_handler(Deploygate)
  end
end

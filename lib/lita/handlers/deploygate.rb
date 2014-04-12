module Lita
  module Handlers
    class Deploygate < Handler
      route(
        /^(deploygate|dg)\sadd\s(\S+)\s(\S+)$/,
        :add,
        command: true,
        help: {
          'deploygate add <username or email> <short name>' =>
          'Add <username or email> to <short name>'
        }
      )

      route(
        /^(deploygate|dg)\sremove\s(\S+)\s(\S+)$/,
        :remove,
        command: true,
        help: {
          'deploygate remove <username or email> <short name>' =>
          'Remove <username or email> from <short name>'
        }
      )

      route(
        /^(deploygate|dg)\slist\s(\S+)$/,
        :list,
        command: true,
        help: {
          'deploygate list <short name>' =>
          'List all users associated with <short name>'
        }
      )

      def self.default_config(config)
        config.user_name      = nil
        config.api_key        = nil
        config.default_app_id = nil
      end

      def add(response)
        short_name = response.matches[0][2]
        user_identifier = response.matches[0][1]
        if valid_app_name?(short_name)
          result = api_request('post',
                               "/#{app_path(short_name)}/members",
                               'users' => "[#{user_identifier}]")
          if result
            response.reply("#{short_name}: #{user_identifier} added")
          else
            response.reply('There was an error making the request to DeployGate')
          end
        else
          response.reply("#{short_name}: unknown application name")
        end
      end

      def remove(response)
        short_name = response.matches[0][2]
        user_identifier = response.matches[0][1]
        if valid_app_name?(short_name)
          result = api_request('delete',
                               "/#{app_path(short_name)}/members",
                               'users' => "[#{user_identifier}]")
          if result
            response.reply("#{short_name}: #{user_identifier} removed")
          else
            response.reply('There was an error making the request to DeployGate')
          end
        else
          response.reply("#{short_name}: unknown application name")
        end
      end

      def list(response)
        short_name = response.matches[0][1]
        if valid_app_name?(short_name)
          result = api_request('get', "/#{app_path(short_name)}/members")
          if result
            users = result['results']['users']
            if users.count > 0
              users.each do |user|
                response.reply("#{short_name}: #{user['name']}, role: #{user['role']}")
              end
            else
              response.reply("#{short_name}: No users")
            end
          else
            response.reply('There was an error making the request to DeployGate')
          end
        else
          response.reply("#{short_name}: unknown application name")
        end
      end

      private

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

        if http_response.status == 200 ||
           http_response.status == 201
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

module Infrastructure
  module Repositories
    class RedisVoteRepository
      def initialize(redis_client = REDIS_CLIENT)
        @redis = redis_client
      end

      # Buscar metadatos de la votacion
      def find_poll(poll_id)
        data = @redis.hgetall("poll:#{poll_id}")
        return nil if data.empty?

        Core::Entities::Poll.new(
          id: data["id"] || poll_id,
          title: data["title"] || "Votacion #{poll_id}",
          description: data["description"] || "",
          status: data["status"] || "open",
          created_at: data["created_at"]
        )
      end

      # Obtener opciones asociadas a la votacion
      def find_options(poll_id)
        counts = @redis.hgetall("poll:#{poll_id}:options")
        details = @redis.hgetall("poll:#{poll_id}:option_details")

        return [] if counts.empty?

        counts.map do |opt_id, vote_count|
          Core::Entities::Option.new(
            id: opt_id,
            poll_id: poll_id,
            text: details[opt_id] || opt_id,
            current_votes: vote_count.to_i
          )
        end
      end

      # Verificar si un votante ya emitio su voto
      def voter_participated?(poll_id, voter_fingerprint)
        @redis.sismember("poll:#{poll_id}:voters", voter_fingerprint)
      end

      # Registro atomico del voto
      def record_vote(poll_id:, option_id:, voter_fingerprint:)
        # 1. Operacion atomica SADD: agrega el identificador al conjunto de votantes
        # Si retorna 0, el votante ya habia votado en esta sesion
        is_new_voter = @redis.sadd("poll:#{poll_id}:voters", voter_fingerprint)
        if is_new_voter == 0
          raise Core::Errors::DuplicateVoteError, "El terminal o delegado #{voter_fingerprint} ya emitio su voto previamente."
        end

        # 2. Operacion atomica HINCRBY: incrementa el contador en memoria en tiempo O(1)
        @redis.hincrby("poll:#{poll_id}:options", option_id, 1)

        # 3. Guardar registro individual de auditoria del voto
        vote_id = SecureRandom.uuid
        now = Time.now.utc.iso8601
        @redis.hset("vote:#{vote_id}", {
          "id" => vote_id,
          "poll_id" => poll_id,
          "option_id" => option_id,
          "voter_fingerprint" => voter_fingerprint,
          "cast_at" => now
        })

        # 4. Retornar los totales consolidados
        calculate_results(poll_id)
      end

      # Obtener resultados consolidados
      def get_poll_results(poll_id)
        poll = find_poll(poll_id)
        return nil unless poll

        options = find_options(poll_id)
        results = calculate_results(poll_id)

        {
          poll: poll.to_h,
          options: options.map(&:to_h),
          totals: results[:totals],
          percentages: results[:percentages],
          total_votes: results[:total_votes]
        }
      end

      # Reiniciar una votacion (util para repeticion de pruebas y sustentacion)
      def reset_poll(poll_id)
        options = @redis.hkeys("poll:#{poll_id}:options")
        options.each do |opt_id|
          @redis.hset("poll:#{poll_id}:options", opt_id, 0)
        end
        @redis.del("poll:#{poll_id}:voters")

        calculate_results(poll_id)
      end

      private

      def calculate_results(poll_id)
        counts = @redis.hgetall("poll:#{poll_id}:options")
        totals = {}
        total_votes = 0

        counts.each do |opt_id, val|
          votes = val.to_i
          totals[opt_id] = votes
          total_votes += votes
        end

        percentages = {}
        totals.each do |opt_id, votes|
          percentages[opt_id] = total_votes > 0 ? ((votes.to_f / total_votes) * 100).round(1) : 0.0
        end

        {
          totals: totals,
          percentages: percentages,
          total_votes: total_votes
        }
      end
    end
  end
end

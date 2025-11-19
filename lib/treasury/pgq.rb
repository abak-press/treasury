module Treasury
  module Pgq
    # http://skytools.projects.postgresql.org/pgq/files/external-sql.html
    # http://skytools.projects.postgresql.org/skytools-3.0/pgq/files/external-sql.html
    # http://skytools.projects.postgresql.org/doc/pgq-sql.html
    # https://github.com/markokr/skytools

    def pgq_create_queue(queue_name, conn)
      conn.select_value("SELECT pgq.create_queue(#{conn.quote queue_name})").to_i
    end

    def pgq_drop_queue(queue_name, conn)
      conn.select_value("SELECT pgq.drop_queue(#{conn.quote queue_name})").to_i
    end

    def pgq_insert_event(queue_name, ev_type, ev_data, extra1 = nil, extra2 = nil, extra3 = nil, extra4 = nil)
      result = connection.select_value(<<~SQL)
        SELECT pgq.insert_event(
          #{connection.quote queue_name},
          #{connection.quote ev_type},
          #{connection.quote ev_data},
          #{connection.quote extra1},
          #{connection.quote extra2},
          #{connection.quote extra3},
          #{connection.quote extra4}
        )
      SQL

      result ? result.to_i : nil
    end

    def pgq_register_consumer(queue_name, consumer_name, conn)
      result = conn.select_value(<<~SQL)
        SELECT pgq.register_consumer(#{conn.quote queue_name}, #{conn.quote consumer_name})
      SQL

      result.to_i
    end

    def pgq_unregister_consumer(queue_name, consumer_name, conn)
      result = conn.select_value(<<~SQL)
        SELECT pgq.unregister_consumer(#{conn.quote queue_name}, #{conn.quote consumer_name})
      SQL

      result.to_i
    end

    def pgq_next_batch(queue_name, consumer_name, conn)
      result = conn.select_value(<<~SQL)
        SELECT pgq.next_batch(#{conn.quote queue_name}, #{conn.quote consumer_name})
      SQL

      result ? result.to_i : nil
    end

    def pgq_get_batch_events(batch_id, conn)
      conn.select_all("SELECT * FROM pgq.get_batch_events(#{batch_id})")
    end

    def get_batch_events_by_cursor(batch_id, cursor_name, fetch_size, extra_where, conn)
      conn.select_all(<<~SQL).to_a
        SELECT * FROM pgq.get_batch_cursor(
          #{batch_id},
          #{conn.quote(cursor_name)},
          #{fetch_size},
          #{conn.quote(extra_where)}
        )
      SQL
    end

    def pgq_event_failed(batch_id, event_id, reason, conn)
      conn.select_value(sanitize_sql(["SELECT pgq.event_failed(?, ?, ?)", batch_id, event_id, reason])).to_i
    end

    def pgq_event_retry(batch_id, event_id, retry_seconds, conn)
      conn.select_value("SELECT pgq.event_retry(#{batch_id}, #{event_id}, #{retry_seconds})").to_i
    end

    def pgq_finish_batch(batch_id, conn)
      conn.select_value("SELECT pgq.finish_batch(#{batch_id})")
    end

    def pgq_get_queue_info(queue_name, conn)
      conn.select_all("SELECT pgq.get_queue_info(#{connection.quote queue_name})")
    end

    def pgq_queue_exists?(queue_name, conn)
      pgq_get_queue_info(queue_name, conn).present?
    end

    def pgq_force_tick(queue_name, conn)
      last_tick = conn.select_value sanitize_sql(["SELECT pgq.force_tick(:queue_name)", {queue_name: queue_name}])
      current_tick = conn.select_value sanitize_sql(["SELECT pgq.force_tick(:queue_name)", {queue_name: queue_name}])
      cnt = 0

      while last_tick != current_tick and cnt < 100
        current_tick = conn.select_value sanitize_sql(["SELECT pgq.force_tick(:queue_name)", {queue_name: queue_name}])
        sleep 0.01
        cnt += 1
      end

      current_tick
    end
  end
end

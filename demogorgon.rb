INOTIFY_SUPPORT = false

require 'rb-inotify' if INOTIFY_SUPPORT
require 'socket'

require './cron'

=begin
inotify flags for use with monitor (from rb-inotify documentation)

:access : A file is accessed (that is, read).
:attrib : A file's metadata is changed (e.g. permissions, timestamps, etc).
:close_write : A file that was opened for writing is closed.
:close_nowrite : A file that was not opened for writing is closed.
:modify : A file is modified.
:open : A file is opened.

Directory-Specific Flags
:moved_from : A file is moved out of the watched directory.
:moved_to : A file is moved into the watched directory.
:create : A file is created in the watched directory.
:delete : A file is deleted in the watched directory.

:delete_self : The watched file or directory itself is deleted.
:move_self : The watched file or directory itself is moved.

Helper Flags
:close : Either :close_write or :close_nowrite is activated.
:move : Either :moved_from or :moved_to is activated.
:all_events : Any event above is activated.

Options Flags
:onlydir : Only watch the path if it's a directory.
:dont_follow : Don't follow symlinks.
:mask_add : Add these flags to the pre-existing flags for this path.
:oneshot : Only send the event once, then shut down the watcher.
:recursive : Recursively watch any subdirectories that are created.
=end

class Demogorgon

  class Bug < StandardError; end
  class InotifyNotSupported < StandardError; end

  def initialize &block
    @notifier = INotify::Notifier.new if INOTIFY_SUPPORT
    @on_connect = {}
    @on_message = {}
    @tail_handlers = {}
    @stdin_handler = nil
    @cron = Cron::Queue.new
    @int_handler = nil
    @term_handler = nil
    @boot_action = lambda{}
    @connections = {}
    @dialog_servers = {}
    @dialogs = {}

    Signal.trap('INT') do
      @int_handler.call() if @int_handler
      exit
    end

    Signal.trap('TERM') do
      @term_handler.call() if @term_handler
      exit(1)
    end

    self.instance_eval &block

    fds = [
      [STDIN],
      @on_connect.keys,
      @on_message.keys,
      @tail_handlers.keys,
      @dialog_servers.keys,
      INOTIFY_SUPPORT ? [@notifier.to_io] : []
    ].flatten(1)

    now = Time.now

    @boot_action.call

    loop do
      ready_set = IO.select(fds, [], [], @cron.eta(now))
      now = Time.now
      if ready_set.nil?
        event = @cron.dequeue!(now)
        event.call() if event
      else
        ready_set[0].each do |io|
          case fd_class(io)
            when :stdin
              msg = io.gets
              @stdin_handler[msg.chomp] if msg && @stdin_handler
            when :connect_for_message
              s = io.accept
              @connections[s] = @on_message[io]
              fds.push(s)
            when :message
              msg = io.gets || ''
              @connections[io][msg.chomp, lambda{|x| io.write(x) rescue nil}]
              @connections.delete(io)
              io.close
              fds.delete(io)
            when :connect
              s = io.accept
              @on_connect[io].call(lambda{|x| s.write(x) rescue nil})
              s.close
            when :dialog_connect
              s = io.accept
              fds.push(s)
              @dialogs[s] = @dialog_servers[io]
              @dialogs[s][:connect][
                s.to_i,
                lambda{|msg| s.write(msg) rescue nil},
                lambda{ s.shutdown }
              ]
            when :dialog
              msg = io.gets
              if msg.nil?
                @dialogs[io][:disconnect][io.to_i]
                @dialogs.delete(io)
                fds.delete(io)
                io.close
              else
                @dialogs[io][:message][io.to_i, msg.chomp]
              end
            when :monitor then @notifier.process
            when :tail
              msg = io.gets
              if msg.nil?
                io.close
                @tail_handlers.delete(io)
                fds.delete(io)
              else
                @tail_handlers[io][msg.chomp]
              end
          end
        end
      end
    end
  end

  def fd_class io
    return :stdin if io == STDIN
    return :connect if @on_connect[io]
    return :connect_for_message if @on_message[io]
    return :tail if @tail_handlers[io]
    return :monitor if INOTIFY_SUPPORT && @notifier.to_io == io
    return :message if @connections.include?(io)
    return :dialog_connect if @dialog_servers.include?(io)
    return :dialog if @dialogs.include?(io)
    raise Bug, "unknown fd class"
  end

  def monitor path, events, &block
    raise InotifyNotSupported unless INOTIFY_SUPPORT
    @notifier.watch(path, *events) do |event|
      block.call(event.absolute_name, event.flags)
    end
  end

  def on_boot &block
    @boot_action = block
  end

  def on_connect port, &block
    server = TCPServer.new port
    @on_connect[server] = block
  end

  def on_message port, &block
    server = TCPServer.new port
    @on_message[server] = block
  end

  def stdin &block
    @stdin_handler = block
  end

  def each_line_in_file path, &block
    f = File.open(path, 'r')
    @tail_handlers[f] = block
  end

  def on_ctrl_c &block
    @int_handler = block
  end

  def on_terminate &block
    @term_handler = block
  end

  def on_schedule raw_spec, &block
    spec = Cron::Spec.new raw_spec
    now = Time.now
    @cron.insert! now, spec, block
  end

  def dialog port, handlers
    server = TCPServer.new port
    @dialog_servers[server] = handlers
  end

end

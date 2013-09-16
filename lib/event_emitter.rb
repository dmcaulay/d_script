
module EventEmitter
  def count
    @events.length
  end

  def on(event, &block)
    @events[event] = block
  end

  def emit(event, *args)
    @events[event].call(*args) if @events[event]
  end

  def remove(event)
    @events.delete(event)
  end
end

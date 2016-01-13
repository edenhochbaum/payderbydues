require_relative 'pdd-camping'

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      PayDerbyDues.create()
    end
  end
end

PayDerbyDues.create()
run PayDerbyDues

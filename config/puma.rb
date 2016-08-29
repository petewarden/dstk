# Change to match your CPU core count
workers 16
port 4567

# Min and Max threads per worker
threads 1, 2

app_dir = File.expand_path("../..", __FILE__)
shared_dir = File.expand_path("shared", app_dir)

# Default to production
rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env

# Set up socket location
bind "unix://#{shared_dir}/sockets/puma.sock"

# Set master PID and state locations
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"


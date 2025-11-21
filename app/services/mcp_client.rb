require 'open3'
require 'json'

class McpClient
  class Error < StandardError; end

  def initialize(command, env = {})
    @command = command
    @env = env
  end

  def call_tool(tool_name, arguments)
    # We use popen3 to interact with the stdio of the MCP server
    Open3.popen3(@env, @command) do |stdin, stdout, stderr, wait_thr|
      begin
        # 1. Initialize
        send_json(stdin, {
          jsonrpc: "2.0",
          id: 1,
          method: "initialize",
          params: {
            protocolVersion: "2024-11-05",
            capabilities: {},
            clientInfo: { name: "rails-app", version: "1.0.0" }
          }
        })

        # Read initialize response
        init_resp = read_response(stdout, 1)
        if init_resp['error']
          raise Error, "Initialization failed: #{init_resp['error']['message']}"
        end

        # 2. Initialized Notification
        send_json(stdin, {
          jsonrpc: "2.0",
          method: "notifications/initialized"
        })

        # 3. Call Tool
        send_json(stdin, {
          jsonrpc: "2.0",
          id: 2,
          method: "tools/call",
          params: {
            name: tool_name,
            arguments: arguments
          }
        })

        # Read tool response
        response = read_response(stdout, 2)
        
        if response['error']
          raise Error, "Tool execution failed: #{response['error']['message']}"
        end

        return response['result']
      ensure
        # Try to close gracefully
        stdin.close rescue nil
        # We don't wait for the thread because we want to return as soon as we have the result
        # and the process might not exit immediately unless we send exit notification.
        # But for a one-off command, killing it or letting it die when pipe closes is okay.
        Process.kill("TERM", wait_thr.pid) rescue nil
      end
    end
  end

  private

  def send_json(io, data)
    io.puts(data.to_json)
    io.flush
  end

  def read_response(io, id)
    io.each_line do |line|
      begin
        data = JSON.parse(line)
        # We are looking for a response with the matching ID
        return data if data['id'] == id
      rescue JSON::ParserError
        # Ignore non-JSON lines (logs, etc.)
      end
    end
    raise Error, "No response received for request #{id}"
  end
end

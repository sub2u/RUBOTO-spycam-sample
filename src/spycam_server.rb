require 'monitor'
require 'camera_helper'
require 'ruboto/util/stack'

class SpycamServer
  extend MonitorMixin

  PORT = 4567

  @@server = nil
  @@camera_data = nil

  def self.start(activity, camera)
    Thread.with_large_stack(512) do
      synchronize do
        if @@server.nil?
          activity.server_status = "Loading"
          require 'webrick'
          activity.server_status = "Loaded"
          @@server = WEBrick::HTTPServer.new(:Port => PORT, :DocumentRoot => "#{activity.files_dir.absolute_path}/")

          @@server.mount_proc('/') do |req, resp|
            case req.path
            when '/', 'index.html'
              CameraHelper.take_picture(self, camera, activity)
              resp.content_type = "text/html"
              resp.body = '<html>
                              <head>
                                <title>Spycam</title>
                              </head>
                              <body>
                                <a href="/"><img src="latest.jpg"></a>
                              </body>
                            </html>'
              raise WEBrick::HTTPStatus::OK
            when '/latest.jpg'
              resp.content_type = "image/jpg"
              resp.body = @@camera_data
              @@camera_data = nil
              raise WEBrick::HTTPStatus::OK
            else
              resp.body = "Unknown path: #{req.path.inspect}"
              raise WEBrick::HTTPStatus::NotFound
            end
          end
          server = @@server
          Thread.new{server.start}
        end
        activity.server_status = "WEBrick started on http://#{get_local_ip_address(activity)}:#{PORT}/"
      end
    end
  end

  def self.camera_data=(data)
    @@camera_data = data
  end

  def self.stop
    synchronize do
      if @@server
        @@server.shutdown
        sleep 0.1 until @@server.status == :Stop
        @@server = nil
      end
    end
  end

  private

  def self.get_local_ip_address(context)
    ip = context.get_system_service(context.class::WIFI_SERVICE).connection_info.ip_address
    return "localhost" if ip == 0
    [0, 8, 16, 24].map{|n| ((ip >> n) & 0xff).to_s}.join(".")
  end

end

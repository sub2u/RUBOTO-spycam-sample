require 'ruboto/activity'
require 'ruboto/widget'
require 'spycam_server'

import android.util.Log
import android.view.Surface
import android.view.WindowManager

ruboto_import_widgets :Button, :LinearLayout, :ScrollView, :TextView
ruboto_import_widget :SurfaceView, "android.view"

class SpycamActivity
  def on_create(bundle)
    super
    rotation = {
        Surface::ROTATION_0 => 0,Surface::ROTATION_90 => 90,Surface::ROTATION_180 => 180,Surface::ROTATION_270 => 270
    }[window_manager.default_display.rotation]
    self.title = "Spycam #{rotation}"
    # self.setRequestedOrientation(android.content.pm.ActivityInfo::SCREEN_ORIENTATION_PORTRAIT)
    window.add_flags(WindowManager::LayoutParams::FLAG_KEEP_SCREEN_ON)

    setContentView(linear_layout(:orientation => :vertical) do
      linear_layout do
        text_view :text => "Server: "
        @server_status_view = text_view
      end
      linear_layout do
        text_view :text => "Picture: "
        @camera_status_view = text_view
      end

      sv = surface_view
      @surface_holder_callback = RubotoSurfaceHolderCallback.new(self, rotation)
      sv.holder.add_callback @surface_holder_callback
      # Deprecated, but still required for older API version
      sv.holder.set_type android.view.SurfaceHolder::SURFACE_TYPE_PUSH_BUFFERS
    end)
  end
  
  def camera_status=(value)
    run_on_ui_thread { @camera_status_view.text = value }
  end

  def server_status=(value)
    run_on_ui_thread { @server_status_view.text = value }
  end

end

class RubotoSurfaceHolderCallback
  def initialize(activity, roation)
    @activity = activity
    @rotation = roation
  end

  def surfaceCreated(holder)
    puts 'RubotoSurfaceHolderCallback#surfaceCreated'
    @camera = android.hardware.Camera.open
    parameters = @camera.parameters
    parameters.picture_format = android.graphics.PixelFormat::JPEG
    parameters.rotation = (360 + (90 - @rotation)) % 360
    parameters.set_picture_size(640, 480)
    @camera.parameters = parameters
    @camera.preview_display = holder
    @camera.display_orientation = (360 + (90 - @rotation)) % 360
    @camera.start_preview
    SpycamServer.start(@activity, @camera)
  end

  def surfaceChanged(holder, format, width, height)
  end

  def surfaceDestroyed(holder)
    SpycamServer.stop
    @camera.stop_preview
    @camera.release
    @camera = nil
  end
end

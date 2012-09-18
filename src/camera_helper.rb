class CameraHelper
  def self.take_picture(server, camera, activity)
    activity.camera_status = "Set volume..."
    am = activity.getSystemService(android.content.Context::AUDIO_SERVICE)
    old_volume = am.get_stream_volume(android.media.AudioManager::STREAM_SYSTEM)
    am.set_stream_volume(android.media.AudioManager::STREAM_SYSTEM, 0, 0)

    activity.camera_status = "Taking picture..."
    picture_taken = false
    camera.take_picture(nil, nil) do |data, camera|
      server.camera_data = String.from_java_bytes(data)
      activity.camera_status = "Gotcha!"

      camera.start_preview
      am.set_stream_volume(android.media.AudioManager::STREAM_SYSTEM, old_volume, 0)
      picture_taken = true
    end
    sleep 0.1 until picture_taken
  end
end
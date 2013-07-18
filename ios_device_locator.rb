require 'base64'
require 'json'
require 'net/http'
require 'net/https'
require 'ostruct'
require 'typhoeus'
require 'uri'

class IOSDeviceLocator

  def initialize username, password
    @username = username
    @password = password
    @partition = nil
    getPartition
  end

  def getDevicesAndLocations
    response = post("/fmipservice/device/#{@username}/initClient")
    devices_json = JSON.parse(response.body)['content']
    devices_json.collect { |device| hash_to_device(device) }
  end

  private

  def getPartition
    response = post("/fmipservice/device/#{@username}/initClient")
    @partition = response.headers['X-Apple-MMe-Host']
  end

  def post(url)
    uri = @partition ? "https://#{@partition}#{url}" : "https://fmipmobile.icloud.com#{url}"

    headers = {
      'Authorization' => "Basic #{Base64.encode64("#{@username}:#{@password}").chomp!}",
      'Content-Type' => 'application/json; charset=utf-8',
      'X-Apple-Find-Api-Ver' => '2.0',
      'X-Apple-Authscheme' => 'UserIdGuest',
      'X-Apple-Realm-Support' => '1.0',
      'User-Agent' => 'Find iPhone/1.3 MeKit (iPad: iPhone OS/4.2.1)',
      'X-Client-Name' => 'iPad',
      'X-Client-UUID' => '0cf3dc501ff812adb0b202baed4f37274b210853',
      'Accept-Language' => 'en-us',
      'Connection' => 'keep-alive'
    }

    Typhoeus::Request.post(uri, headers: headers, followlocation: true, verbose: true, maxredirs: 10)
  end

  def hash_to_device(hsh)
    device = OpenStruct.new
    device.id = hsh['id']
    device.name = hsh['name']
    device.class = hsh['deviceClass']
    device.display_name = hsh['deviceDisplayName']
    device.model = hsh['deviceModel']

    if (location = hsh['location'])
      device.latitude = location['latitude']
      device.longitude = location['longitude']
      device.time = location['timeStamp']
    end

    device
  end

end


# USAGE: $ ./ruby ios_device_locator username password
if __FILE__ == $0
  r = IOSDeviceLocator.new(ARGV[0], ARGV[1])
  devices = r.getDevicesAndLocations
  devices.each { |d| puts "#{d.name} - (#{d.latitude}, #{d.longitude})" }
end

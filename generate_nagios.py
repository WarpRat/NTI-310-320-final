import os
import requests

def write_nagios_cfg(hosts):
    if not os.path.isdir('tmp'):
        os.mkdir('tmp')
    for i in hosts:
        os.system('./scripts/generate_nagios_conf.sh %s %s' % (i['name'], i['ip']))
    
def send_cfg():
    nagios_ip = requests.get('http://metadata.google.internal/computeMetadata/v1/project/attributes/nagios_ip', headers='Metadata-Flavor: Google')
    os.system('gcloud compute scp ./tmp/* %s:/etc/nagios/conf.d/' % nagios_ip)
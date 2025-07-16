from os import environ
import xml.etree.ElementTree as ET
from os.path import abspath, expanduser

def include_configuration(file_path, included_ids):
    included_ids = set(included_ids.split(','))

    # Parse XML file
    tree = ET.parse(file_path)
    root = tree.getroot()

    # Define namespaces to search XML elements correctly
    ET.register_namespace("", 'http://maven.apache.org/SETTINGS/1.1.0')
    namespaces = {'': 'http://maven.apache.org/SETTINGS/1.1.0'}

    # Include only servers with IDs in included_ids
    servers = root.find('servers', namespaces)
    if servers is not None:
        for server in list(servers.findall('server', namespaces)):
            server_id = server.find('id', namespaces).text
            if server_id not in included_ids:
                servers.remove(server)

    # Include only mirrors with IDs in included_ids
    mirrors = root.find('mirrors', namespaces)
    if mirrors is not None:
        for mirror in list(mirrors.findall('mirror', namespaces)):
            mirror_id = mirror.find('id', namespaces).text
            if mirror_id not in included_ids:
                mirrors.remove(mirror)

    # Include only repositories with IDs in included_ids
    profiles = root.find('profiles', namespaces)
    if profiles is not None:
        for profile in list(profiles.findall('profile', namespaces)):
            repositories = profile.find('repositories', namespaces)
            if repositories is not None:
                for repo in list(repositories.findall('repository', namespaces)):
                    repo_id = repo.find('id', namespaces).text
                    if repo_id not in included_ids:
                        repositories.remove(repo)

    # Write the modified XML back to the file
    tree.write(file_path)

# Usage
file_path = abspath(expanduser(environ.get('MVN_SETTINGS', '~/.m2/settings.xml')))
included_ids = environ.get('INCLUDED_IDS', '') + ',pictet-release-repo,pictet-snapshot-repo'
include_configuration(file_path, included_ids)

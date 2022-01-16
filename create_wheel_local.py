import os
from wheel.util import urlsafe_b64encode, native
from wheel.archive import archive_wheelfile
import hashlib
import csv
from email.message import Message
from email.generator import Generator
import shutil
import tempfile
import platform

import sys

def open_for_csv(name, mode):
    if sys.version_info[0] < 3:
        kwargs = {}
        mode += 'b'
    else:
        kwargs = {'newline': '', 'encoding': 'utf-8'}

    return open(name, mode, **kwargs)

pyversion = str(sys.version_info[0])+str(sys.version_info[1])
os_name   = platform.system()
bitness   = sys.argv[1]
arch      = sys.argv[2]
dir_name  = sys.argv[3]

if os_name=="Linux":
  if arch=="manylinux1-x86":
    arch = "manylinux1_i686"
  elif arch=="manylinux1-x64":
    arch = "manylinux1_x68_64"
  tag = "cp%s-none-%s" % (pyversion,arch.replace("-","_"))
elif os_name=="Darwin":
  tag = ["cp%s-none-macosx_10_13_x86_64" % (pyversion),
         "cp%s-none-macosx_10_13_intel" % (pyversion)]
elif os_name=="Windows":
  if bitness=="64":
    tag = "cp%s-none-win_amd64" % pyversion
  else:
    tag = "cp%s-none-win32" % pyversion
else:
  raise Exception()

def write_record(bdist_dir, distinfo_dir):        

      record_path = os.path.join(distinfo_dir, 'RECORD')
      record_relpath = os.path.relpath(record_path, bdist_dir)

      def walk():
          for dir, dirs, files in os.walk(bdist_dir):
              dirs.sort()
              for f in sorted(files):
                  yield os.path.join(dir, f)

      def skip(path):
          """Wheel hashes every possible file."""
          return (path == record_relpath)

      with open_for_csv(record_path, 'w+') as record_file:
          writer = csv.writer(record_file)
          for path in walk():
              relpath = os.path.relpath(path, bdist_dir)
              if skip(relpath):
                  hash = ''
                  size = ''
              else:
                  with open(path, 'rb') as f:
                      data = f.read()
                  digest = hashlib.sha256(data).digest()
                  hash = 'sha256=' + native(urlsafe_b64encode(digest))
                  size = len(data)
              record_path = os.path.relpath(
                  path, bdist_dir).replace(os.path.sep, '/')
              writer.writerow((record_path, hash, size))
             
work_dir = tempfile.mkdtemp()


shutil.copytree(dir_name,os.path.join(work_dir,"dummy"))


wheel_dist_name = "dummy-1.0"
bdist_dir = work_dir

import tempfile


distinfo_dir = os.path.join(work_dir,'%s.dist-info' % wheel_dist_name)
os.makedirs(distinfo_dir)


msg = Message()
msg['Wheel-Version'] = '1.0'  # of the spec
#msg['Generator'] = generator
msg['Root-Is-Purelib'] = "false"
if isinstance(tag,list):
  for t in tag: msg["Tag"] = t
else:
  msg["Tag"] = tag



wheelfile_path = os.path.join(distinfo_dir, 'WHEEL')
with open(wheelfile_path, 'w') as f:
    Generator(f, maxheaderlen=0).flatten(msg)

metadata_path = os.path.join(distinfo_dir, 'METADATA')
with open(metadata_path, 'w') as f:
    f.write("""Metadata-Version: 2.0
Name: dummy
Version: 1.0
Summary: Dummy
Home-page: http://dummy.org
Author: Ted Dummy
Author-email:  ted@dummy.org
License: GNU Lesser General Public License v3 or later (LGPLv3+)
Download-URL: http://dummy.org

Nothing to see here.""")


#wheel_dist_name = wheel_dist_name+".post1"
if isinstance(tag,list):
  fullname = wheel_dist_name+"-"+tag[0]
  for t in tag[1:]:
    fullname+="."+t.split("-")[-1]
else:
  fullname = wheel_dist_name+"-"+tag

write_record(bdist_dir, distinfo_dir)
archive_wheelfile(fullname,work_dir)

print("::set-output name=wheel_name::"+fullname+".whl")

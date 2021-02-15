import os
import json
import boto3
import time
from PyPDF2 import PdfFileMerger
import traceback


def handler(event, context):
    # Set the variables
    bucket_name = 'chorme-chris-2021'
    bucket_url = 'https://chorme-chris-2021.s3-us-west-2.amazonaws.com/'
    s3 = boto3.client('s3')
    links = event["links"]
    i = 1
    for link in links:
        os.system("/var/task/chrome-linux/chrome --headless --disable-dev-shm-usage --virtual-time-budget=10000 --window-size=1280x1696 --hide-scrollbars --disable-gpu --single-process --no-zygote --no-sandbox --ignore-certificate-errors --v=99 --print-to-pdf-no-header --print-to-pdf=/tmp/"+str(i)+".pdf "+link)
        i = i+1
        time.sleep(2)
    os.chdir('/tmp')
    pdfs = [a for a in os.listdir("/tmp") if a.endswith(".pdf")]
    merger = PdfFileMerger()
    filename = str(int(time.time()))+'.pdf'
    try:
        if len(links) == 1:
            s3.upload_file(
                '1.pdf', bucket_name, filename,
                ExtraArgs={'ACL': 'public-read'}
            )
        else:
            for pdf in pdfs:
                merger.append(open(pdf, 'rb'))
            with open('result.pdf', 'wb') as fout:
                merger.write(fout)
            s3.upload_file(
                'result.pdf', bucket_name, filename,
                ExtraArgs={'ACL': 'public-read'}
            )
    except Exception as e:
        print(e)
        traceback.print_exc()
        result = {
            "result": "merge process failed please retry"
        }
        filename = "E"

    if filename != "E":
        result = {
            "result": bucket_url+filename
        }
    return result

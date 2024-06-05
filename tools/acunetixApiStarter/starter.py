import requests
import time

#Get scans count module
def getScansCount():
    getScansUrl = "https://localhost:3443/api/v1/scans?q=status:processing,queued,scheduled,starting"
    authHeader = {'X-Auth': 'paste_here_your_api_key','Content-type':'application/json'}
    getRequest = requests.get(getScansUrl, headers=authHeader, verify=False)
    getResponse = getRequest.json()
    scansCount = getResponse["pagination"]["count"]
    return(scansCount)

#Add new scan module
def createScan(domain):
    addTargetUrl = "https://localhost:3443/api/v1/targets"
    scheduleScanUrl = "https://localhost:3443/api/v1/scans"
    postAuthHeader = {'X-Auth': 'paste_here_your_api_key','Content-type':'application/json','Accept':'application/json'}
    addTargetPost = requests.post(addTargetUrl, json={"address":domain,"description":"autoSQLIWave1","type":"default","criticality":30}, headers=postAuthHeader, verify=False)
    newTargetId = addTargetPost.json()["target_id"]
    scheduleScanPost = requests.post(scheduleScanUrl, json={"target_id":newTargetId, "profile_id":"11111111-1111-1111-1111-111111111113", "schedule": {"disable":False,"start_date":None,"time_sensitive":False}}, headers=postAuthHeader, verify=False)

#Main loop
print("Hello! The script is starting...")
targetList = open("./targets/testpack.txt", "r")
lines = targetList.readlines()
for domain in lines:
    while(True):
        time.sleep(10)
        currentScanCount = getScansCount()
        if (currentScanCount < 5):
            break
        else:
            print("Already 5 or more scans, waiting...")
    print("Adding new scan: " + domain)
    createScan(domain.strip())
print("Done! Quitting...")

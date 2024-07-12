
import os


## NOTE: Customize me.
SERVER_PATH = "mtlsim:PrjTimingTaint"


## NOTE: Keep Me Default
DEFAULT_OPT="-av --relative --delete --checksum"
DEFAULT_EXCLUDELIST=[
  ".DS_Store",
  "__pycache__",
]


def rsync(SRC_PATH, DST_PATH, FILELIST,
          EXTRA_OPT="",
          EXTRA_EXCLUDELIST=[]):
  command = ""

  ## STEP1: Options
  command += f"rsync {DEFAULT_OPT} {EXTRA_OPT} "
  
  ## STEP2: Exclude list
  for file in DEFAULT_EXCLUDELIST + EXTRA_EXCLUDELIST:
    command += f"--exclude={file} "
  
  ## STEP3: Srouce
  command += f"{SRC_PATH}/./"

  ## STEP4: File list
  ## NOTE: If {XXX} only has 1 path inside, it does not work. And folder/{XXX,}
  #        will match all path in the folder.
  if len(FILELIST)==1:
    command += f"{FILELIST[0]}"
  else:
    ## NOTE: Wildcard for server should be wrapped by "", to avoid being
    #        resolved locally.
    if ":" in SRC_PATH: command += f"\""
    command += f"{{"
    for file in FILELIST:
      command += f"{file},"
    command  = command[:-1] + f"}}"
    if ":" in SRC_PATH: command += f"\""
  command += f" "

  ## STEP5: Destination
  command += f"{DST_PATH}"
  
  ## STEP6: Run
  print("[command to run]: ", command)
  os.system(command)


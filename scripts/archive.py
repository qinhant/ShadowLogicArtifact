
import os


def archive(target_location, target_folderName, exclude_list):

  command = f"cp -r . {target_location}/{target_folderName}"
  print("[command to run]: ", command)
  os.system(command)


  for file in exclude_list:
    command = f"find {target_location}/{target_folderName} -name \"{file}\" -print -exec rm -rf {{}} +"
    print("[command to run]: ", command)
    os.system(command)


  command = f"cd {target_location} && zip -r {target_folderName}.zip {target_folderName}"
  print("[command to run]: ", command)
  os.system(command)

  command = f"rm -rf {target_location}/{target_folderName}"
  print("[command to run]: ", command)
  os.system(command)




if __name__ == "__main__":

  archive("~/Downloads", "contractShadowLogic_artifact", 
    [".git", ".DS_Store", "__pycache__", "archive.py"])


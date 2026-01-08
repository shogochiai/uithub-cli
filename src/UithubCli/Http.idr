module UithubCli.Http

import System
import System.File
import Data.String

import UithubCli.Config

%default total

-- Build uithub URL from owner/repo
export
uithubUrl : String -> String -> String
uithubUrl owner repo = "https://uithub.com/" ++ owner ++ "/" ++ repo

-- Fetch content using curl (external command)
-- Returns HTTP status code and content, or error message
export
covering
fetchUithub : String -> String -> String -> IO (Either String String)
fetchUithub apiKey owner repo = do
  let url = uithubUrl owner repo
  let tmpFile = "/tmp/uithub-cli-" ++ owner ++ "-" ++ repo ++ ".md"
  let statusFile = "/tmp/uithub-cli-" ++ owner ++ "-" ++ repo ++ ".status"
  let curlCmd = "curl -s -w '%{http_code}' -H 'Authorization: Bearer " ++ apiKey ++ "' '" ++ url ++ "' -o '" ++ tmpFile ++ "' > '" ++ statusFile ++ "'"
  _ <- system curlCmd
  Right statusStr <- readFile statusFile
    | Left _ => pure $ Left "Failed to get HTTP status"
  _ <- system $ "rm -f '" ++ statusFile ++ "'"
  let status = trim statusStr
  if status == "200"
    then do
      Right content <- readFile tmpFile
        | Left err => pure $ Left $ "Failed to read content: " ++ show err
      _ <- system $ "rm -f '" ++ tmpFile ++ "'"
      pure $ Right content
    else do
      _ <- system $ "rm -f '" ++ tmpFile ++ "'"
      pure $ Left $ "HTTP " ++ status ++ " from uithub.com/" ++ owner ++ "/" ++ repo

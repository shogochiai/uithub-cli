module UithubCli.Config

import System
import System.File
import System.Directory
import Data.String
import Data.List

%default total

public export
record Config where
  constructor MkConfig
  apiKey : Maybe String

export
configDir : IO String
configDir = do
  Just home <- getEnv "HOME"
    | Nothing => pure ".uithub-cli"
  pure $ home ++ "/.uithub-cli"

export
configPath : IO String
configPath = do
  dir <- configDir
  pure $ dir ++ "/config"

export
cacheDir : IO String
cacheDir = do
  dir <- configDir
  pure $ dir ++ "/cache"

isFileExists : FileError -> Bool
isFileExists FileExists = True
isFileExists _ = False

export
covering
ensureConfigDir : IO (Either FileError ())
ensureConfigDir = do
  dir <- configDir
  cache <- cacheDir
  Right _ <- createDir dir
    | Left err => if isFileExists err then pure (Right ()) else pure (Left err)
  Right _ <- createDir cache
    | Left err => if isFileExists err then pure (Right ()) else pure (Left err)
  pure (Right ())

export
covering
readConfig : IO Config
readConfig = do
  path <- configPath
  Right content <- readFile path
    | Left _ => pure $ MkConfig Nothing
  let keyLine = find (isPrefixOf "apiKey=") (lines content)
  case keyLine of
    Just line => pure $ MkConfig (Just $ substr 7 (length line) line)
    Nothing => pure $ MkConfig Nothing

export
covering
writeConfig : Config -> IO (Either FileError ())
writeConfig cfg = do
  _ <- ensureConfigDir
  path <- configPath
  let content = case cfg.apiKey of
        Just key => "apiKey=" ++ key ++ "\n"
        Nothing => ""
  writeFile path content

export
covering
setApiKey : String -> IO (Either FileError ())
setApiKey key = do
  cfg <- readConfig
  writeConfig ({ apiKey := Just key } cfg)

export
covering
getApiKey : IO (Maybe String)
getApiKey = do
  cfg <- readConfig
  pure cfg.apiKey

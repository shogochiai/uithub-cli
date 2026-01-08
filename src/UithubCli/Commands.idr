module UithubCli.Commands

import System
import System.File
import Data.String
import Data.List

import UithubCli.Config
import UithubCli.Cache
import UithubCli.Http

%default total

covering
withApiKey : (String -> IO ()) -> IO ()
withApiKey action = do
  Just key <- getApiKey
    | Nothing => do
        putStrLn "Error: API key not configured"
        putStrLn "Run: uithub-cli config set-key <your-api-key>"
  action key

covering
fetchAndCache : String -> String -> String -> IO ()
fetchAndCache key owner repo = do
  putStrLn $ "Fetching " ++ owner ++ "/" ++ repo ++ "..."
  Right content <- fetchUithub key owner repo
    | Left err => putStrLn $ "Error: " ++ err
  Right _ <- saveCachedContent owner repo content
    | Left _ => putStrLn "Error saving cache"
  putStrLn $ "Cached " ++ owner ++ "/" ++ repo ++ " (" ++ show (length content) ++ " bytes)"

export
covering
cmdFetch : String -> IO ()
cmdFetch url = do
  Just (owner, repo) <- pure $ parseRepoUrl url
    | Nothing => putStrLn $ "Error: Invalid repository URL: " ++ url
  withApiKey $ \key => fetchAndCache key owner repo

export
covering
cmdGet : String -> IO ()
cmdGet url = do
  Just (owner, repo) <- pure $ parseRepoUrl url
    | Nothing => putStrLn $ "Error: Invalid repository URL: " ++ url
  Just content <- getCachedContent owner repo
    | Nothing => do
        putStrLn $ "Not cached, fetching..."
        withApiKey $ \key => fetchAndCache key owner repo
  putStr content

export
covering
cmdUpdate : String -> IO ()
cmdUpdate url = do
  Just (owner, repo) <- pure $ parseRepoUrl url
    | Nothing => putStrLn $ "Error: Invalid repository URL: " ++ url
  withApiKey $ \key => fetchAndCache key owner repo

export
covering
cmdList : IO ()
cmdList = do
  repos <- listCachedRepos
  case repos of
    [] => putStrLn "No cached repositories"
    _ => do
      putStrLn "Cached repositories:"
      traverse_ (\(o, r) => putStrLn $ "  " ++ o ++ "/" ++ r) repos

export
covering
cmdSetKey : String -> IO ()
cmdSetKey key = do
  Right _ <- setApiKey key
    | Left _ => putStrLn "Error saving API key"
  putStrLn "API key saved"

export
covering
cmdShowConfig : IO ()
cmdShowConfig = do
  cfg <- readConfig
  case cfg.apiKey of
    Just key => putStrLn $ "API Key: " ++ substr 0 10 key ++ "...(hidden)"
    Nothing => putStrLn "API Key: not set"

module Main

import System
import System.File
import System.Directory
import Data.String
import Data.List

import UithubCli.Config
import UithubCli.Cache
import UithubCli.Http
import UithubCli.Commands

%default total

printUsage : IO ()
printUsage = do
  putStrLn "uithub-cli - Fetch GitHub repos as LLM-friendly markdown"
  putStrLn ""
  putStrLn "Usage:"
  putStrLn "  uithub-cli fetch <github-url>   Fetch and cache repository"
  putStrLn "  uithub-cli get <github-url>     Get from cache (fetch if missing)"
  putStrLn "  uithub-cli update <github-url>  Force re-fetch"
  putStrLn "  uithub-cli list                 List cached repositories"
  putStrLn "  uithub-cli config set-key <key> Set API key"
  putStrLn "  uithub-cli config show          Show current config"
  putStrLn ""
  putStrLn "Examples:"
  putStrLn "  uithub-cli fetch https://github.com/anthropics/claude-code"
  putStrLn "  uithub-cli get anthropics/claude-code"

covering
parseArgs : List String -> IO ()
parseArgs ["fetch", url] = cmdFetch url
parseArgs ["get", url] = cmdGet url
parseArgs ["update", url] = cmdUpdate url
parseArgs ["list"] = cmdList
parseArgs ["config", "set-key", key] = cmdSetKey key
parseArgs ["config", "show"] = cmdShowConfig
parseArgs _ = printUsage

covering
main : IO ()
main = do
  args <- getArgs
  case args of
    _ :: rest => parseArgs rest
    [] => printUsage

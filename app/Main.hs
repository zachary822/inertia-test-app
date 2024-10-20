{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Main where

import Data.Aeson
import Data.Text (Text)
import Data.Text.Lazy qualified as TL
import Data.Text.Lazy.Encoding (decodeUtf8)
import GHC.Generics
import Network.Wai.Middleware.RequestLogger
import Text.Blaze.Html (preEscapedToHtml)
import Text.Blaze.Html.Renderer.Utf8 (renderHtml)
import Text.Hamlet
import Web.Scotty hiding (defaultOptions)

data Page a = Page
  { component :: Text
  , props :: a
  , url :: Text
  , version :: Text
  }
  deriving (Generic, Show, Eq)

instance (ToJSON a) => ToJSON (Page a) where
  toEncoding = genericToEncoding defaultOptions

entryPoint :: (ToJSON a) => Page a -> Html
entryPoint page =
  preEscapedToHtml . decodeUtf8 $
    ( "<div id=\"app\" data-page='"
        <> encode page
        <> "'></div>"
    )

devJs :: Html
devJs =
  [shamlet|
          <script type="module" src="/public/@vite/client">
          <script type="module">
            import RefreshRuntime from 'http://localhost:5173/public/@react-refresh'
            RefreshRuntime.injectIntoGlobalHook(window)
            window.$RefreshReg$ = () => {}
            window.$RefreshSig$ = () => (type) => type
            window.__vite_plugin_react_preamble_installed__ = true
          |]

baseInertia :: (ToJSON a) => Page a -> Html
baseInertia page =
  [shamlet|
          $doctype 5
          <html>
            <head>
              <meta charset="UTF-8">
              <link rel="icon" type="image/svg+xml" href="/public/vite.svg">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Vite + React + TS
              ^{devJs}
            <body>
              ^{entryPoint page}
              <script type="module" src="/public/src/main.tsx">
          |]

inertia :: (ToJSON a) => Page a -> ActionM ()
inertia page = do
  isInertia <- (Just "true" ==) <$> header "X-Inertia"

  if isInertia
    then do
      setHeader "Vary" "X-Inertia"
      setHeader "X-Inertia" "true"
      json page
    else
      (raw . renderHtml) (baseInertia page)

app :: ScottyM ()
app = do
  middleware logStdoutDev

  get "/" $ do
    inertia
      Page{component = "App", props = object [], url = "/", version = "yay"}

  -- catch all
  get (regex "^/public/(.*)$") $ do
    p :: TL.Text <- pathParam "1"
    redirect ("http://localhost:5173/public/" <> p)

main :: IO ()
main = do
  let port = 3000

  scotty port app

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE CPP #-}

import Reflex.Dom
import Data.Text as T
import Data.Text.Encoding as T
import Data.ByteString.Char8 as BS8

main = do
#if defined (ghcjs_HOST_OS)
  -- Use the widget normally as the main entry point
  mainWidget topWidget
  return ()
#else
  (_,bs) <- renderStatic $ topWidget
  -- Use the generated bytestring as the body of page
  -- And include the all.js in the end
  BS8.putStrLn bs
#endif

-- Widget supporting Static Rendering
topWidget :: ((MonadHold t m,
                 PostBuild t m,
                 Prerender js m,
                 DomBuilder t m,
                 TriggerEvent t m,
                 PerformEvent t m))
           => m ()
topWidget = do
  el "h1" $ text "Some heading"

  -- Use constDyn for widget which need Dynamic values
  elDynAttr "div" (constDyn ("id" =: "mydiv")) $ text "hello"

  -- The Events will only fire in the Immediate DomBuilder
  ev <- button "Click to test"

  divClass "static-text" $ widgetHold (text "Initial text")
    (text "Changed text" <$ ev)

  -- The MonadHold widgets have to be put inside prerender
  c <- prerender (return $ constDyn 0) (Reflex.Dom.count ev)
  display c

  message <- getWebSocketMessage ("some message sent to websocket" <$ ev)

  divClass "message" $ widgetHold (text "Waiting For message")
    (text <$> message)

  return ()

getWebSocketMessage ::
  (_)
  => Event t Text
  -> m (Event t Text)
getWebSocketMessage messageEv = prerender (return never) $ do
  let sendEv = (\m -> [T.encodeUtf8 m]) <$> messageEv
  ws <- webSocket "ws://echo.websocket.org" $ WebSocketConfig sendEv never False
  return (T.decodeUtf8 <$> _webSocket_recv ws)

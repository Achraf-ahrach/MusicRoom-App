
======== Exception caught by rendering library =====================================================
The following assertion was thrown during layout:
A RenderFlex overflowed by 44 pixels on the right.

The relevant error-causing widget was:
Row Row:file:///goinfre/abouzanb/MusicRoom-App/mobile/lib/screens/playlist_detail_screen.dart:601:46
The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and black striped pattern. This is usually caused by the contents being too big for the RenderFlex.

Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be seen. If the content is legitimately bigger than the available space, consider clipping it with a ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex, like a ListView.

The specific RenderFlex in question is: RenderFlex#9ca02 relayoutBoundary=up18 OVERFLOWING
...  parentData: <none> (can use size)
...  constraints: BoxConstraints(0.0<=w<=368.0, 0.0<=h<=Infinity)
...  size: Size(368.0, 20.0)
...  direction: horizontal
...  mainAxisAlignment: start
...  mainAxisSize: min
...  crossAxisAlignment: center
...  textDirection: ltr
...  verticalDirection: down
...  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
====================================================================================================
I/flutter (16132): STOMP connected for Playlist 0a3ab5a5-6788-4401-bb9f-0df208dc9736






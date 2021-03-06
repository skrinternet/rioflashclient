/*
 * Copyright (C) 2011, Edmundo Albuquerque de Souza e Silva.
 *
 * This file may be distributed under the terms of the Q Public License
 * as defined by Trolltech AS of Norway and appearing in the file
 * LICENSE.QPL included in the packaging of this file.
 *
 * THIS FILE IS PROVIDED AS IS WITH NO WARRANTY OF ANY KIND, INCLUDING
 * THE WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL,
 * INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
 * FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
 * NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION
 * WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

package rioflashclient2.media {
  import org.osmf.elements.SWFElement;
  import org.osmf.elements.VideoElement;
  import org.osmf.media.MediaElement;
  import org.osmf.media.MediaFactory;
  import org.osmf.media.MediaFactoryItem;
  import org.osmf.net.NetLoader;
  
  import rioflashclient2.net.RioServerNetLoader;
  import rioflashclient2.net.RioServerSWFLoader;

  public class PlayerMediaFactory extends MediaFactory {
    private var netLoader:NetLoader;
  	private var swfLoader:RioServerSWFLoader;
    public function PlayerMediaFactory() {
      super();

      init();
    }

    private function init():void {
      netLoader = new RioServerNetLoader();
      addItem
        ( new MediaFactoryItem
          ( "org.osmf.elements.video"
          , netLoader.canHandleResource
          , function():MediaElement
            {
              return new VideoElement(null, netLoader);
            }
          )
        );
		swfLoader = new RioServerSWFLoader();
		addItem
		( new MediaFactoryItem
			( "org.osmf.elements.swf"
				, swfLoader.canHandleResource
				, function():MediaElement
				{
					return new SWFElement(null, swfLoader);
				}
			)
		);
    }
  }
}

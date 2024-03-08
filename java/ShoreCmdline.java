import java.awt.image.*;
import java.io.*;
import javax.imageio.*;
import java.nio.*;
import de.fraunhofer.iis.shore.wrapper.*;
import de.fraunhofer.iis.shore.wrapper.IMessageCallback;


class ShoreCmdline {
    /**
     * This method builds a string representation of the information
     * stored in a ShoreContent object. 
     *
     * @param c The ShoreContent object to be process
     */
    public static String getInfo(ShoreContent content) {
        if(content == null) {
            return "";
        }

        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append(String.format("Number of objects: %d\n",
                content.GetObjectCount()));

        for(int shoreObj = 0; shoreObj < content.GetObjectCount(); ++shoreObj) {
           ShoreObject shoreObject = content.GetObject(shoreObj);
           ShoreRegion region = shoreObject.GetRegion();
           String type = shoreObject.GetType();
           stringBuilder.append(String.format("Object[%d]: %s @ %.2fx%.2f"+
                       " <-> %.2fx%.2f\n", shoreObj, type, region.GetLeft(),
                       region.GetTop(), region.GetBottom(), region.GetRight()));

           stringBuilder.append(String.format("\tNumber of Attributes: %d\n",
                       shoreObject.GetAttributeCount()));
           for(int attr = 0; attr < shoreObject.GetAttributeCount(); ++attr) {
               String key = shoreObject.GetAttributeKey(attr);
               String value = shoreObject.GetAttribute(attr);
               stringBuilder.append(String.format("\t\t%s: %s\n",
                           key, value));
           }

           stringBuilder.append(String.format("\tNumber of Ratings: %d\n",
                       shoreObject.GetRatingCount()));
           for(int rating = 0; rating < shoreObject.GetRatingCount(); ++rating) {
               String key = shoreObject.GetRatingKey(rating);
               Float value = shoreObject.GetRating(rating);
               stringBuilder.append(String.format("\t\t%s: %.2f\n",
                           key, value));
           }

           stringBuilder.append(String.format("\tNumber of Markers: %d\n", 
                       shoreObject.GetMarkerCount()));
           for(int marker = 0; marker < shoreObject.GetMarkerCount(); ++marker) {
               String key = shoreObject.GetMarkerKey(marker);
               ShoreMarker sm = shoreObject.GetMarker(marker);
               stringBuilder.append(String.format("\t\t%s: %.2f x %.2f\n",
                           key, sm.GetX(), sm.GetY()));
           }

           stringBuilder.append("---\n");
        }
        return stringBuilder.toString();
    }

    public static void main(String args[]) {
        /*
         * Set a callback to receive info/error
         * messages from SHORE
         */
        Shore.SetMessageCall(new IMessageCallback() {
            @Override
            public void MessageCallback(String s) {
                System.out.println("Java Shore Message handler: " + s);
            }
        });
        /*
         * Create the SHORE engine, see the documentation for
         * an explanation of the parameters
         */
        ShoreEngine engine = Shore.CreateFaceEngine(
                (float)0.00, 
                true,
                2,
                "Face.Front",
                1,
                9,
                0,
                0,
                "Spatial",
                false,
                "Off",
                "Off",
                "On",
                "Dnn",
                "Dnn",
                "On",
                "Off",
                false,
                false);


        System.out.println("Createa Engine: " + engine);
        /*
         * Iterate over all input files and read them into a ByteBuffer
         */
        for ( String arg : args ) {
            try {
                BufferedImage bufferedImage = ImageIO.read(new File(arg));
                if(bufferedImage == null) {
                    System.err.println("Cannot read " + arg);
                    continue;
                }
                int width = bufferedImage.getWidth();
                int height = bufferedImage.getHeight();
                System.out.println(arg + ": " + width + " x " +height);
                int rgbBuffer[] = new int[width * height];
                ByteBuffer bb = ByteBuffer.allocateDirect(4 * width * height);
                bb.order(ByteOrder.LITTLE_ENDIAN);
                bufferedImage.getRGB(0, 0, width, height, rgbBuffer, 0, width);
                bb.asIntBuffer().put(rgbBuffer);
                /* 
                 * Process the image buffer with our SHORE engine
                 * See the documentation for an explanation of the parameters
                 */
                ShoreContent c = engine.Process(bb, width, height, 3, 4,
                        4*width, 1, "RGB");
                System.out.println(getInfo(c));
            }catch(IOException e) {
                System.err.println("Cannot open Imagefile " + arg);
            }
        }
        /*
         * Do not forget to clean up the engine once the processing of all
         * images is done
         */
        Shore.DeleteEngine(engine);
    }
}

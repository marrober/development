import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.File;
import java.io.IOException;

public class Analyzer {
    public static void main(String[] args) {
        if (args.length == 0 || args[0].isEmpty()) {
            System.out.println("Filename required as argument");
            System.exit(0);
        }

        String filename = args[0];
        File file = new File(filename);
        ObjectMapper mapper = new ObjectMapper();

        try {
            // Read and parse the JSON file
            JsonNode componentTemplates = mapper.readTree(file);
            
            if (!componentTemplates.isArray()) {
                System.out.println("Error: JSON root must be an array.");
                return;
            }

            int numberComponentTemplates = componentTemplates.size();
            System.out.println(numberComponentTemplates + " component templates to be analysed.");

            for (JsonNode componentTemplate : componentTemplates) {
                String description = "";
                String name = "";

                // Logic for extracting 'user' (owner)
                if (componentTemplate.has("user") && !componentTemplate.get("user").isNull()) {
                    String owner = componentTemplate.get("user").asText();

                    if (owner.contains("(")) {
                        String[] splitOwner = owner.split("\\(");
                        String[] splitName = splitOwner[0].split(",");
                        
                        if (splitName.length >= 2) {
                            // Reconstruct name: FirstName + LastName (removing leading space)
                            name = splitName[1].trim() + " " + splitName[0].trim();
                        } else {
                            name = owner;
                        }
                    } else {
                        name = owner;
                    }
                } else {
                    name = "<missing>";
                }

                // Logic for description
                if (componentTemplate.has("description") && !componentTemplate.get("description").isNull()) {
                    description = componentTemplate.get("description").asText();
                }

                // Output formatted string
                String templateName = componentTemplate.path("name").asText("");
                String version = componentTemplate.path("version").asText("");
                
                System.out.println(templateName + "#" + version + "#" + name + "#" + description);
            }

        } catch (IOException e) {
            System.err.println("Error reading file: " + e.getMessage());
        }
    }
}

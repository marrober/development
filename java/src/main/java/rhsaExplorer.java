import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.JsonNodeType;
// import tools.jackson.annotation.JsonProperty;
import org.json.JSONObject;
import java.io.File;
import tools.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.io.BufferedReader;
import java.io.InputStreamReader;

import java.io.IOException;


public class rhsaExplorer {

    public static class User {
        @JsonProperty("full_name")
        public String name;
        public int age;

        // Default constructor for Jackson
        public User() {}

        public User(String name, int age) {
            this.name = name;
            this.age = age;
        }
    }

    public static void main(String[] args) {
        //  mapper = JsonMapper.builder().build();
        // User user = new User("Alice Smith", 30);

 
        /* String filename = args[0];
        String filename = "~/Downloads/simple.json";
        System.out.println("Processing file : " + filename);
        File file = new File(filename);
        ObjectMapper mapper = new ObjectMapper(); */


        ObjectMapper mapper = new ObjectMapper();
        JsonNode rootNode = mapper.readTree(new File("content/simple.json"));
        String firstName = rootNode.path("firstName").asText(); 
        System.out.println("firstName : " + firstName);
        JsonNodeType dataNodeType = rootNode.path("data").getNodeType();
        System.out.println("data node type : " + dataNodeType);
        String data_age = rootNode.path("data").path("age").asText();
        System.out.println("data/age : " + data_age);


        ProcessBuilder pb = new ProcessBuilder(
            "curl", "-X", "GET", "-k", "-s", "-H", "\"authorization: Bearer $ROX_API_TOKEN\"", "\"https://central-stackrox.apps.ocp4.mr-openshift.co.uk/v1/images?query=CVE:CVE-2024-45337\"" 
        );
        pb.redirectErrorStream(true); 
            
        Process process = pb.start();
            
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        }
            
        int exitCode = process.waitFor();
        System.out.println("Exited with code: " + exitCode);

        /* Serialize POJO to String
        String jacksonJson = mapper.writeValueAsString(user);
        System.out.println("Jackson 3.0 Serialized: " + jacksonJson);

        // Parse back into a Tree Model (JsonNode)
        JsonNode node = mapper.readTree(jacksonJson);
        System.out.println("Jackson Read Name: " + node.get("full_name").asText());

        // 2. Using org.json (20251224 version)
        // Create a JSON object from the existing string
        JSONObject orgJsonObject = new JSONObject(jacksonJson);
        orgJsonObject.put("active", true); // Add new data dynamically
            
        System.out.println("org.json Modified: " + orgJsonObject.toString());
        System.out.println("org.json Read Age: " + orgJsonObject.getInt("age")); */
    }
}

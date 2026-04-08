/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package templates;

/**
 *
 * @author laraashour
 */
import java.util.List;
import java.util.Map;

public interface TemplateAPI {
    String getTemplate(String key) throws Exception;
    boolean updateTemplate(String key, String value) throws Exception;
    Map<String, String> getAllTemplates() throws Exception;
    List<String> getAllTemplateKeys() throws Exception;
}


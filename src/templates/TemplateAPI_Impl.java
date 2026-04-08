/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package templates;

/**
 *
 * @author laraashour
 */
import database.DBConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class TemplateAPI_Impl implements TemplateAPI {

    @Override
    public String getTemplate(String key) throws Exception {
        String sql = "SELECT template_value FROM ca_templates WHERE template_key = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (conn == null) {
                throw new Exception("Database connection failed.");
            }

            ps.setString(1, key);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("template_value");
                }
            }
        }

        throw new Exception("Template not found: " + key);
    }

    @Override
    public boolean updateTemplate(String key, String value) throws Exception {
        String sql = "UPDATE ca_templates SET template_value = ? WHERE template_key = ?";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            if (conn == null) {
                throw new Exception("Database connection failed.");
            }

            ps.setString(1, value);
            ps.setString(2, key);

            return ps.executeUpdate() > 0;
        }
    }

    @Override
    public Map<String, String> getAllTemplates() throws Exception {
        Map<String, String> templates = new LinkedHashMap<>();

        String sql = "SELECT template_key, template_value FROM ca_templates ORDER BY template_key";

        try (Connection conn = DBConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (conn == null) {
                throw new Exception("Database connection failed.");
            }

            while (rs.next()) {
                templates.put(
                    rs.getString("template_key"),
                    rs.getString("template_value")
                );
            }
        }

        return templates;
    }


@Override
public List<String> getAllTemplateKeys() throws Exception {
    List<String> keys = new ArrayList<>();

    String sql = "SELECT template_key FROM ca_templates ORDER BY template_key";

    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {

        if (conn == null) {
            throw new Exception("Database connection failed.");
        }

        while (rs.next()) {
            keys.add(rs.getString("template_key"));
        }
    }

    return keys;
  }
}
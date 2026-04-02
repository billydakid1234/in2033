package Backend;

import Backend.PU_COMMS_API;
import javax.mail.*;
import javax.mail.internet.*;
import java.util.Properties;

/**
 * we only need to supply html code, email address and subject, the rest of the email configuration will be handled by this class
 */
public class PU_COMMS_API_Impl implements PU_COMMS_API {

    // Email configuration
    private String senderEmail;
    private String senderPassword;
    private String smtpHost;
    private int smtpPort;

    public PU_COMMS_API_Impl(String senderEmail, String senderPassword, String smtpHost, int smtpPort) {
        this.senderEmail = senderEmail;
        this.senderPassword = senderPassword;
        this.smtpHost = smtpHost;
        this.smtpPort = smtpPort;
    }

    @Override
    public boolean sendEmail(String recipient, String subject, String content) {
        Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.host", smtpHost);
        props.put("mail.smtp.port", String.valueOf(smtpPort));

        Session session = Session.getInstance(props, new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(senderEmail, senderPassword);
            }
        });

        try {
            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(senderEmail));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipient));
            message.setSubject(subject);
            message.setContent(content, "text/html; charset=utf-8");

            Transport.send(message);
            return true;
        } catch (MessagingException e) {
            e.printStackTrace();
            return false;
        }
    }
}

    
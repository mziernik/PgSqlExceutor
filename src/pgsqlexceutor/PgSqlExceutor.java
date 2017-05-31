/*
 */
package pgsqlexceutor;

import java.io.*;
import java.lang.reflect.InvocationTargetException;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.event.ActionEvent;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.*;
import javafx.scene.text.Font;
import javafx.stage.Stage;

/**
 *
 * @author user
 */
public class PgSqlExceutor extends Application {

    final static Button btnRun = new Button("Uruchom");
    final static TextArea ta = new TextArea();
    final static ToolBar tb = new ToolBar();
    static Config config;
    static File[] files;

    public static void main(String[] args) throws InterruptedException {
        launch(args);
    }

    @Override
    public void start(Stage primaryStage) {

        try {
            Class.forName("org.postgresql.Driver");

        } catch (Throwable e) {
            showException(e);
            System.exit(0);
            return;
        }
        try {

            files = new File("").getCanonicalFile()
                    .listFiles((File dir, String name)
                            -> name.toLowerCase().endsWith(".sql"));

        } catch (Throwable e) {
            showException(e);
            System.exit(0);
            return;
        }

        ta.setText("Pliki:\n");

        for (File f : files)
            ta.appendText(f.getName() + "\n");

        ta.setEditable(false);

        config = Config.load();

        TextField tfHost = new TextField(config.host);
        tfHost.setTooltip(new Tooltip("Host"));

        TextField tfDatabase = new TextField(config.db);
        tfDatabase.setTooltip(new Tooltip("Nazwa bazy"));

        TextField tfUser = new TextField(config.user);
        tfUser.setTooltip(new Tooltip("Użytkownik"));

        PasswordField tfPass = new PasswordField();
        tfPass.setText(config.pass);
        tfPass.setTooltip(new Tooltip("Hasło"));

        btnRun.setOnAction((ActionEvent t) -> {
            config.host = tfHost.getText().trim();
            config.db = tfDatabase.getText().trim();
            config.user = tfUser.getText().trim();
            config.pass = tfPass.getText().trim();
            tb.setDisable(true);
            ta.setText("");
            new Executor().start();
        });

        tb.getItems().addAll(
                btnRun,
                new Separator(),
                tfHost,
                tfDatabase,
                tfUser,
                tfPass
        );

        ta.setFont(Font.font("Consolas"));

        BorderPane pane = new BorderPane();
        pane.setTop(tb);
        pane.setCenter(ta);
        Scene scene = new Scene(pane, 700, 400);
        primaryStage.setScene(scene);
        primaryStage.setTitle("PgSqlExecutor");
        primaryStage.show();
    }

    public static void showException(final Throwable ex) {
        showException(null, ex);
    }

    public static void showException(String f, final Throwable ex) {

        if (!Platform.isFxApplicationThread()) {
            Platform.runLater(() -> {
                showException(f, ex);
            });
            return;
        }

        Throwable e = ex;
        while (e != null && e.getCause() != null
                && (e instanceof InvocationTargetException || e instanceof RuntimeException))
            e = e.getCause();

        Alert alert = new Alert(Alert.AlertType.ERROR);
        alert.setTitle(f != null ? f : e.getClass().getSimpleName());
        alert.setHeaderText(e.getLocalizedMessage());

        alert.setWidth(500);

        StringWriter sw = new StringWriter();
        PrintWriter pw = new PrintWriter(sw);
        ex.printStackTrace(pw);
        String exceptionText = sw.toString();

        Label label = new Label("Stos wywołań:");

        TextArea textArea = new TextArea(exceptionText);
        textArea.setEditable(false);
        textArea.setWrapText(false);

        textArea.setMaxWidth(Double.MAX_VALUE);
        textArea.setMaxHeight(Double.MAX_VALUE);
        GridPane.setVgrow(textArea, Priority.ALWAYS);
        GridPane.setHgrow(textArea, Priority.ALWAYS);

        GridPane expContent = new GridPane();
        expContent.setMaxWidth(Double.MAX_VALUE);
        expContent.add(label, 0, 0);
        expContent.add(textArea, 0, 1);

        alert.getDialogPane().setExpandableContent(expContent);

        alert.showAndWait();
    }

    public static void alertInfo(String text) {
        sync(() -> {
            Alert alert = new Alert(Alert.AlertType.INFORMATION);
            alert.setHeaderText(null);
            alert.setContentText(text);
            alert.showAndWait();
        });

    }

    public static void sync(final Runnable intf) {
        if (!Platform.isFxApplicationThread()) {
            Platform.runLater(() -> {
                sync(intf);
            });
            return;
        }

        try {
            intf.run();
        } catch (Throwable e) {
            showException(e);
        }
    }
}

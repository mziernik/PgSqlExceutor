/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package pgsqlexceutor;

import java.io.File;
import java.nio.file.Files;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLWarning;
import java.sql.Statement;
import javafx.application.Platform;
import static pgsqlexceutor.PgSqlExceutor.*;

/**
 *
 * @author milosz
 */
public class Executor extends Thread {

    @Override
    public void run() {
        try {

            config.save();

            try (Connection c = DriverManager
                    .getConnection("jdbc:postgresql://" + config.host
                            + "/" + config.db,
                            config.user, config.pass)) {

                c.setAutoCommit(false);

                if (files == null || files.length == 0) {
                    alertInfo("Nie znaleziono plików .SQL");
                    return;
                }

                Platform.runLater(() -> {
                    ta.appendText("- BEGIN -\n");
                });

                for (File f : files)
                    try (Statement stmt = c.createStatement()) {

                        Platform.runLater(() -> {
                            ta.appendText("\n\n---------------- " + f.getName() + " --------------------\n");
                        });

                        byte[] data = Files.readAllBytes(f.toPath());

                        boolean bom = data.length > 3
                                && (data[0] & 0xFF) == 0xef
                                && (data[1] & 0xFF) == 0xbb
                                && (data[2] & 0xFF) == 0xbf;

                        String qry = bom ? new String(data, 3, data.length - 3, "UTF-8")
                                : new String(data, "UTF-8");

                        long ts = System.currentTimeMillis();
                        stmt.execute(qry);

                        SQLWarning warns = stmt.getWarnings();
                        if (warns != null)
                            Platform.runLater(() -> {
                                ta.appendText(warns.toString() + "\n");
                            });

                        final long time = System.currentTimeMillis() - ts;
                        Platform.runLater(() -> {
                            ta.appendText("- OK (" + time + "ms) -\n");
                        });

                    } catch (Throwable e) {
                        Platform.runLater(() -> {
                            ta.appendText(
                                    " - ERR: " + e.getLocalizedMessage() + " -\n"
                                    + "\n- ROLLBACK -\n");
                        });
                        c.rollback();
                        showException(f.getName(), e);
                        return;
                    }

                Platform.runLater(() -> {
                    ta.appendText("\n- COMMIT -\n");
                });
                c.commit();

            }

        } catch (Throwable e) {
            Platform.runLater(() -> {
                ta.appendText(
                        " - ERR: " + e.getLocalizedMessage() + " -\n"
                        + "\n- ROLLBACK -\n");
            });

            showException(e);
        } finally {
            Platform.runLater(() -> {
                tb.setDisable(false);
            });
        }
    }

}

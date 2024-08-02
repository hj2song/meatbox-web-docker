package kr.gbnet.common.listener;

import kr.gbnet.common.constant.Const;
import kr.gbnet.common.tool.SlackTool;
import lombok.Setter;
import lombok.SneakyThrows;
import org.apache.commons.lang.StringUtils;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.stereotype.Component;

import java.net.InetAddress;
import java.util.HashMap;
import java.util.Map;

public class MeatboxApplicationRunner implements ApplicationListener<ContextRefreshedEvent> {

    @Setter
    private String serviceName;


    @SneakyThrows
    @Override
    public void onApplicationEvent(ContextRefreshedEvent contextRefreshedEvent) {

        if (StringUtils.isNotEmpty(Const.LOCATION)
            && Const.LOCATION_RELEASE.equals(Const.LOCATION)) {
            Map<String, Object> params = new HashMap<>();
            params.put("IP", InetAddress.getLocalHost().getHostAddress());
            params.put("Prop", Const.LOCATION);
            params.put("Sevice", serviceName);
            //SlackTool.sendDeployMessage(params,"#deploy");
        }

    }


}
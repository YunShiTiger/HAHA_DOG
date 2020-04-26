select zh_TASK.ZHIXINGRJH,zh_TASK.LRSJ, zh_jys.*
from zh_TASK,zh_jys
where zh_TASK.AUTOORIGINUUID = zh_jys.UUID
and zh_TASK.LRSJ>:latest
and rownum<1000
order by zh_TASK.LRSJ
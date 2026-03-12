package com.example.alarmmaster.alarm.repository

import com.example.alarmmaster.alarm.data.dao.AlarmPlanDao
import com.example.alarmmaster.alarm.domain.AlarmPlan

class AlarmRepositoryImpl(
    private val alarmPlanDao: AlarmPlanDao,
) : AlarmRepository {
    override suspend fun upsert(plan: AlarmPlan) {
        alarmPlanDao.upsert(plan.toEntity())
    }

    override suspend fun delete(alarmId: Long) {
        alarmPlanDao.deleteById(alarmId)
    }

    override suspend fun getById(alarmId: Long): AlarmPlan? {
        return alarmPlanDao.getById(alarmId)?.toDomain()
    }

    override suspend fun getAll(): List<AlarmPlan> {
        return alarmPlanDao.getAllOrdered().map { it.toDomain() }
    }
}

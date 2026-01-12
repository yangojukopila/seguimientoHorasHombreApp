import { Injectable } from '@angular/core';
import { SupabaseService } from './supabase.service';
import { ReportFilters, TimeRecord, DashboardStats, HoursBreakdown } from '../models';
import * as XLSX from 'xlsx';
import { format } from 'date-fns';

@Injectable({
    providedIn: 'root'
})
export class ReportsService {
    constructor(private supabase: SupabaseService) { }

    async getTimeRecords(filters: ReportFilters = {}) {
        let query = this.supabase
            .from('time_records')
            .select(`
        *,
        employee:employees(*),
        project:projects(*),
        island:islands(*)
      `)
            .order('check_in', { ascending: false });

        if (filters.start_date) {
            query = query.gte('check_in', filters.start_date);
        }

        if (filters.end_date) {
            query = query.lte('check_in', filters.end_date);
        }

        if (filters.employee_id) {
            query = query.eq('employee_id', filters.employee_id);
        }

        if (filters.project_id) {
            query = query.eq('project_id', filters.project_id);
        }

        return await query;
    }

    async getDashboardStats(): Promise<DashboardStats> {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todayStr = today.toISOString();

        const weekAgo = new Date(today);
        weekAgo.setDate(weekAgo.getDate() - 7);
        const weekAgoStr = weekAgo.toISOString();

        // Get active employees count
        const { count: activeEmployees } = await this.supabase
            .from('employees')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'active');

        // Get active projects count
        const { count: activeProjects } = await this.supabase
            .from('projects')
            .select('*', { count: 'exact', head: true })
            .eq('status', 'active');

        // Get today's check-ins
        const { count: todayCheckins } = await this.supabase
            .from('time_records')
            .select('*', { count: 'exact', head: true })
            .gte('check_in', todayStr);

        // Get this week's hours
        const { data: weekRecords } = await this.supabase
            .from('time_records')
            .select('hours_breakdown')
            .gte('check_in', weekAgoStr)
            .not('check_out', 'is', null);

        // Aggregate hours
        const weekHours: HoursBreakdown = {
            ordinaria_diurna: 0,
            ordinaria_nocturna: 0,
            extra_diurna: 0,
            extra_nocturna: 0,
            dominical_festiva_diurna: 0,
            dominical_festiva_nocturna: 0
        };

        if (weekRecords) {
            weekRecords.forEach((record: any) => {
                const breakdown = record.hours_breakdown;
                weekHours.ordinaria_diurna += breakdown.ordinaria_diurna || 0;
                weekHours.ordinaria_nocturna += breakdown.ordinaria_nocturna || 0;
                weekHours.extra_diurna += breakdown.extra_diurna || 0;
                weekHours.extra_nocturna += breakdown.extra_nocturna || 0;
                weekHours.dominical_festiva_diurna += breakdown.dominical_festiva_diurna || 0;
                weekHours.dominical_festiva_nocturna += breakdown.dominical_festiva_nocturna || 0;
            });
        }

        return {
            active_employees: activeEmployees || 0,
            active_projects: activeProjects || 0,
            today_checkins: todayCheckins || 0,
            week_hours: weekHours
        };
    }

    exportToExcel(records: TimeRecord[], filename: string = 'reporte-horas') {
        // Prepare data for Excel
        const excelData = records.map(record => ({
            'Fecha Entrada': format(new Date(record.check_in), 'dd/MM/yyyy HH:mm'),
            'Fecha Salida': record.check_out ? format(new Date(record.check_out), 'dd/MM/yyyy HH:mm') : 'En curso',
            'Empleado': (record.employee as any)?.full_name || '',
            'Cédula': (record.employee as any)?.cedula || '',
            'Proyecto': (record.project as any)?.name || '',
            'Código Proyecto': (record.project as any)?.code || '',
            'Isla': (record.island as any)?.name || '',
            'Ordinaria Diurna': record.hours_breakdown.ordinaria_diurna,
            'Ordinaria Nocturna': record.hours_breakdown.ordinaria_nocturna,
            'Extra Diurna': record.hours_breakdown.extra_diurna,
            'Extra Nocturna': record.hours_breakdown.extra_nocturna,
            'Dominical/Festiva Diurna': record.hours_breakdown.dominical_festiva_diurna,
            'Dominical/Festiva Nocturna': record.hours_breakdown.dominical_festiva_nocturna,
            'Total Horas': this.getTotalHours(record.hours_breakdown)
        }));

        // Create workbook
        const ws = XLSX.utils.json_to_sheet(excelData);
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, 'Reporte');

        // Save file
        const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');
        XLSX.writeFile(wb, `${filename}-${timestamp}.xlsx`);
    }

    exportToCSV(records: TimeRecord[], filename: string = 'reporte-horas') {
        // Prepare data for CSV
        const csvData = records.map(record => ({
            'Fecha Entrada': format(new Date(record.check_in), 'dd/MM/yyyy HH:mm'),
            'Fecha Salida': record.check_out ? format(new Date(record.check_out), 'dd/MM/yyyy HH:mm') : 'En curso',
            'Empleado': (record.employee as any)?.full_name || '',
            'Cédula': (record.employee as any)?.cedula || '',
            'Proyecto': (record.project as any)?.name || '',
            'Código Proyecto': (record.project as any)?.code || '',
            'Isla': (record.island as any)?.name || '',
            'Ordinaria Diurna': record.hours_breakdown.ordinaria_diurna,
            'Ordinaria Nocturna': record.hours_breakdown.ordinaria_nocturna,
            'Extra Diurna': record.hours_breakdown.extra_diurna,
            'Extra Nocturna': record.hours_breakdown.extra_nocturna,
            'Dominical/Festiva Diurna': record.hours_breakdown.dominical_festiva_diurna,
            'Dominical/Festiva Nocturna': record.hours_breakdown.dominical_festiva_nocturna,
            'Total Horas': this.getTotalHours(record.hours_breakdown)
        }));

        // Create workbook and export as CSV
        const ws = XLSX.utils.json_to_sheet(csvData);
        const csv = XLSX.utils.sheet_to_csv(ws);

        // Download
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);
        const timestamp = format(new Date(), 'yyyyMMdd-HHmmss');

        link.setAttribute('href', url);
        link.setAttribute('download', `${filename}-${timestamp}.csv`);
        link.style.visibility = 'hidden';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }

    private getTotalHours(breakdown: HoursBreakdown): number {
        return (
            breakdown.ordinaria_diurna +
            breakdown.ordinaria_nocturna +
            breakdown.extra_diurna +
            breakdown.extra_nocturna +
            breakdown.dominical_festiva_diurna +
            breakdown.dominical_festiva_nocturna
        );
    }

    async generateHolidays(year: number) {
        return await this.supabase.rpc('fn_generate_holidays', { p_year: year });
    }

    async getHolidays(year?: number) {
        let query = this.supabase
            .from('holidays')
            .select('*')
            .order('date');

        if (year) {
            query = query.eq('year', year);
        }

        return await query;
    }
}
